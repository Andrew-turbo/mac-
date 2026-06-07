import Foundation

struct ScannerService {
    private let sizer = DirectorySizer()

    func scan(includeDeveloperCaches: Bool = true, excludedPaths: [String] = []) async -> ScanSummary {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let normalizedExcludedPaths = normalizeExcludedPaths(excludedPaths, home: home)
        let candidates = (scanCandidates(home: home, includeDeveloperCaches: includeDeveloperCaches) + appCacheCandidates(home: home))
            .filter { !isExcluded($0.url, excludedPaths: normalizedExcludedPaths) }

        let items = candidates.map { candidate in
            let result = sizer.sizeOfDirectory(at: candidate.url)
            return ScanItem(
                name: candidate.name,
                path: candidate.url.path,
                category: candidate.category,
                risk: candidate.risk,
                canClean: candidate.canClean,
                bytes: result.bytes,
                isAccessible: result.isAccessible
            )
        }

        return ScanSummary(scannedAt: Date(), items: items.filter { $0.bytes > 0 || !$0.isAccessible })
    }

    private func scanCandidates(home: URL, includeDeveloperCaches: Bool) -> [ScanCandidate] {
        var candidates = [
            ScanCandidate(
                name: "Chrome 缓存",
                url: home.appending(path: "Library/Caches/Google/Chrome"),
                category: .browserCache,
                risk: .low,
                canClean: true
            ),
            ScanCandidate(
                name: "Safari 缓存",
                url: home.appending(path: "Library/Caches/com.apple.Safari"),
                category: .browserCache,
                risk: .low,
                canClean: true
            ),
            ScanCandidate(
                name: "Edge 缓存",
                url: home.appending(path: "Library/Caches/Microsoft Edge"),
                category: .browserCache,
                risk: .low,
                canClean: true
            ),
            ScanCandidate(
                name: "Firefox 缓存",
                url: home.appending(path: "Library/Caches/Firefox"),
                category: .browserCache,
                risk: .low,
                canClean: true
            ),
            ScanCandidate(
                name: "用户日志",
                url: home.appending(path: "Library/Logs"),
                category: .logs,
                risk: .medium,
                canClean: true
            ),
            ScanCandidate(
                name: "诊断报告",
                url: home.appending(path: "Library/Logs/DiagnosticReports"),
                category: .logs,
                risk: .low,
                canClean: true
            ),
            ScanCandidate(
                name: "下载目录",
                url: home.appending(path: "Downloads"),
                category: .downloads,
                risk: .high,
                canClean: false
            ),
            ScanCandidate(
                name: "废纸篓",
                url: home.appending(path: ".Trash"),
                category: .trash,
                risk: .medium,
                canClean: true
            )
        ]

        if includeDeveloperCaches {
            candidates.append(
                ScanCandidate(
                    name: "Xcode DerivedData",
                    url: home.appending(path: "Library/Developer/Xcode/DerivedData"),
                    category: .developerCache,
                    risk: .medium,
                    canClean: true
                )
            )
        }

        return candidates
    }

    private func appCacheCandidates(home: URL) -> [ScanCandidate] {
        let cachesURL = home.appending(path: "Library/Caches")
        let excludedPrefixes = [
            cachesURL.appending(path: "Google").path,
            cachesURL.appending(path: "com.apple.Safari").path,
            cachesURL.appending(path: "Microsoft Edge").path,
            cachesURL.appending(path: "Firefox").path
        ]

        guard let children = try? FileManager.default.contentsOfDirectory(
            at: cachesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return children.compactMap { url in
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
                return nil
            }

            guard !excludedPrefixes.contains(where: { url.path.hasPrefix($0) }) else {
                return nil
            }

            return ScanCandidate(
                name: url.lastPathComponent,
                url: url,
                category: .appCache,
                risk: .medium,
                canClean: false
            )
        }
    }

    private func normalizeExcludedPaths(_ paths: [String], home: URL) -> [String] {
        paths.compactMap { path in
            let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }

            let expandedPath: String
            if trimmed == "~" {
                expandedPath = home.path
            } else if trimmed.hasPrefix("~/") {
                expandedPath = home.appending(path: String(trimmed.dropFirst(2))).path
            } else {
                expandedPath = trimmed
            }

            return URL(filePath: expandedPath).standardizedFileURL.path
        }
    }

    private func isExcluded(_ url: URL, excludedPaths: [String]) -> Bool {
        let path = url.standardizedFileURL.path

        return excludedPaths.contains { excludedPath in
            path == excludedPath || path.hasPrefix(excludedPath + "/")
        }
    }

}

private struct ScanCandidate {
    let name: String
    let url: URL
    let category: ScanCategory
    let risk: RiskLevel
    let canClean: Bool
}
