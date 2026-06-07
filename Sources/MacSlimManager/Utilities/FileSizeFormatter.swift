import Foundation

enum StorageFormatter {
    static func string(from bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
