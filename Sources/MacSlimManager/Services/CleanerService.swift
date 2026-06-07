import Foundation

struct CleanerService {
    func clean(items: [ScanItem], allowMediumRisk: Bool = false) async -> CleanReport {
        let results = items.map { item in
            clean(item: item, allowMediumRisk: allowMediumRisk)
        }

        return CleanReport(cleanedAt: Date(), results: results)
    }

    private func clean(item: ScanItem, allowMediumRisk: Bool) -> CleanResult {
        let isAllowed = item.canClean && (item.risk == .low || (allowMediumRisk && item.risk == .medium))

        guard isAllowed else {
            return CleanResult(
                itemName: item.name,
                path: item.path,
                bytesBeforeClean: item.bytes,
                success: false,
                message: "该项目未被允许清理"
            )
        }

        let url = URL(filePath: item.path)
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard isSafeUserDirectory(url) else {
            return CleanResult(
                itemName: item.name,
                path: item.path,
                bytesBeforeClean: item.bytes,
                success: false,
                message: "该路径不在允许的用户目录范围内"
            )
        }

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return CleanResult(
                itemName: item.name,
                path: item.path,
                bytesBeforeClean: item.bytes,
                success: false,
                message: "路径不存在或不是目录"
            )
        }

        do {
            let children = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

            for child in children {
                try fileManager.removeItem(at: child)
            }

            return CleanResult(
                itemName: item.name,
                path: item.path,
                bytesBeforeClean: item.bytes,
                success: true,
                message: "已清理"
            )
        } catch {
            return CleanResult(
                itemName: item.name,
                path: item.path,
                bytesBeforeClean: item.bytes,
                success: false,
                message: error.localizedDescription
            )
        }
    }

    private func isSafeUserDirectory(_ url: URL) -> Bool {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        let path = url.standardizedFileURL.path

        return path != homePath && path.hasPrefix(homePath + "/")
    }
}

struct CleanHistoryStore {
    private let fileManager = FileManager.default

    func append(report: CleanReport) {
        guard let logURL else { return }

        do {
            try fileManager.createDirectory(
                at: logURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            var entries = loadEntries(from: logURL)
            entries.append(CleanHistoryEntry(report: report))
            entries = Array(entries.suffix(100))

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(entries)
            try data.write(to: logURL, options: .atomic)
        } catch {
            assertionFailure("Failed to write clean history: \(error.localizedDescription)")
        }
    }

    private var logURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "MacSlimManager")
            .appending(path: "clean-history.json")
    }

    private func loadEntries(from url: URL) -> [CleanHistoryEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return (try? decoder.decode([CleanHistoryEntry].self, from: data)) ?? []
    }
}

private struct CleanHistoryEntry: Codable {
    let id: UUID
    let cleanedAt: Date
    let releasedBytes: Int64
    let successCount: Int
    let failureCount: Int
    let results: [CleanHistoryResult]

    init(report: CleanReport) {
        id = report.id
        cleanedAt = report.cleanedAt
        releasedBytes = report.releasedBytes
        successCount = report.successCount
        failureCount = report.failureCount
        results = report.results.map(CleanHistoryResult.init(result:))
    }
}

private struct CleanHistoryResult: Codable {
    let itemName: String
    let path: String
    let bytesBeforeClean: Int64
    let success: Bool
    let message: String

    init(result: CleanResult) {
        itemName = result.itemName
        path = result.path
        bytesBeforeClean = result.bytesBeforeClean
        success = result.success
        message = result.message
    }
}
