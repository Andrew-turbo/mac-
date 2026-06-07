import Foundation

struct DirectorySizer {
    func sizeOfDirectory(at url: URL) -> (bytes: Int64, isAccessible: Bool) {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return (0, false)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return (0, false)
        }

        var total: Int64 = 0
        var accessible = true

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .totalFileAllocatedSizeKey])
                guard values.isRegularFile == true else { continue }
                let allocated = values.totalFileAllocatedSize ?? values.fileSize ?? 0
                total += Int64(allocated)
            } catch {
                accessible = false
            }
        }

        return (total, accessible)
    }
}
