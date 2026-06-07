import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var summary: ScanSummary?
    var cleanReport: CleanReport?
    var isScanning = false
    var isCleaning = false

    private let scanner = ScannerService()
    private let cleaner = CleanerService()
    private let notificationService = NotificationService()
    private let cleanHistoryStore = CleanHistoryStore()
    private var lastNotificationAt: Date?
    private var backgroundScanTask: Task<Void, Never>?

    func startBackgroundScanning(settings: SettingsStore) {
        guard backgroundScanTask == nil else { return }

        backgroundScanTask = Task { @MainActor [weak self] in
            await self?.runScan(settings: settings)

            while !Task.isCancelled {
                let seconds = UInt64(settings.backgroundScanIntervalMinutes * 60)
                try? await Task.sleep(for: .seconds(seconds))

                guard !Task.isCancelled else { break }
                guard settings.backgroundScanningEnabled else { continue }

                await self?.runScan(settings: settings)
            }
        }
    }

    func runScan(settings: SettingsStore) async {
        guard !isScanning else { return }

        isScanning = true
        let newSummary = await scanner.scan(
            includeDeveloperCaches: settings.scanDeveloperCaches,
            excludedPaths: settings.excludedPaths
        )
        summary = newSummary
        isScanning = false

        await notifyIfNeeded(summary: newSummary, settings: settings)
    }

    func runClean(items: [ScanItem], settings: SettingsStore, allowMediumRisk: Bool = false) async {
        guard !isCleaning else { return }

        isCleaning = true
        let report = await cleaner.clean(items: items, allowMediumRisk: allowMediumRisk)
        cleanHistoryStore.append(report: report)
        cleanReport = report
        await runScan(settings: settings)
        isCleaning = false
    }

    func requestNotificationPermission(settings: SettingsStore) async -> Bool {
        let granted = await notificationService.requestAuthorization()
        settings.desktopNotificationsEnabled = granted
        return granted
    }

    private func notifyIfNeeded(summary: ScanSummary, settings: SettingsStore) async {
        guard settings.desktopNotificationsEnabled, summary.totalBytes >= settings.thresholdBytes else {
            return
        }

        if let lastNotificationAt, Date().timeIntervalSince(lastNotificationAt) < 60 * 60 {
            return
        }

        await notificationService.notifyStorageThresholdExceeded(
            totalBytes: summary.totalBytes,
            thresholdGB: settings.thresholdGB
        )
        lastNotificationAt = Date()
    }
}
