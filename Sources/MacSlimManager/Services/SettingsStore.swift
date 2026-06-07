import Foundation
import Observation

@Observable
final class SettingsStore {
    var thresholdGB: Double {
        didSet {
            thresholdGB = max(1, min(thresholdGB, 1_000))
            defaults.set(thresholdGB, forKey: Keys.thresholdGB)
        }
    }

    var desktopNotificationsEnabled: Bool {
        didSet {
            defaults.set(desktopNotificationsEnabled, forKey: Keys.desktopNotificationsEnabled)
        }
    }

    var scanDeveloperCaches: Bool {
        didSet {
            defaults.set(scanDeveloperCaches, forKey: Keys.scanDeveloperCaches)
        }
    }

    var backgroundScanningEnabled: Bool {
        didSet {
            defaults.set(backgroundScanningEnabled, forKey: Keys.backgroundScanningEnabled)
        }
    }

    var backgroundScanIntervalMinutes: Double {
        didSet {
            backgroundScanIntervalMinutes = max(15, min(backgroundScanIntervalMinutes, 360))
            defaults.set(backgroundScanIntervalMinutes, forKey: Keys.backgroundScanIntervalMinutes)
        }
    }

    var excludedPaths: [String] {
        didSet {
            defaults.set(excludedPaths, forKey: Keys.excludedPaths)
        }
    }

    var thresholdBytes: Int64 {
        Int64(thresholdGB * 1024 * 1024 * 1024)
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedThreshold = defaults.double(forKey: Keys.thresholdGB)
        thresholdGB = savedThreshold > 0 ? savedThreshold : 150
        desktopNotificationsEnabled = defaults.bool(forKey: Keys.desktopNotificationsEnabled)

        if defaults.object(forKey: Keys.scanDeveloperCaches) == nil {
            scanDeveloperCaches = true
        } else {
            scanDeveloperCaches = defaults.bool(forKey: Keys.scanDeveloperCaches)
        }

        if defaults.object(forKey: Keys.backgroundScanningEnabled) == nil {
            backgroundScanningEnabled = true
        } else {
            backgroundScanningEnabled = defaults.bool(forKey: Keys.backgroundScanningEnabled)
        }

        let savedInterval = defaults.double(forKey: Keys.backgroundScanIntervalMinutes)
        backgroundScanIntervalMinutes = savedInterval > 0 ? savedInterval : 60
        excludedPaths = defaults.stringArray(forKey: Keys.excludedPaths) ?? []
    }

    func addExcludedPath(_ rawPath: String) {
        let path = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty, !excludedPaths.contains(path) else { return }

        excludedPaths.append(path)
    }

    func removeExcludedPath(_ path: String) {
        excludedPaths.removeAll { $0 == path }
    }
}

private enum Keys {
    static let thresholdGB = "settings.thresholdGB"
    static let desktopNotificationsEnabled = "settings.desktopNotificationsEnabled"
    static let scanDeveloperCaches = "settings.scanDeveloperCaches"
    static let backgroundScanningEnabled = "settings.backgroundScanningEnabled"
    static let backgroundScanIntervalMinutes = "settings.backgroundScanIntervalMinutes"
    static let excludedPaths = "settings.excludedPaths"
}
