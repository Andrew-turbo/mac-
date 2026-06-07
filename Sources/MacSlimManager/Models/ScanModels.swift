import Foundation
import SwiftUI

enum RiskLevel: String, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            "低风险"
        case .medium:
            "需确认"
        case .high:
            "只展示"
        }
    }

    var color: Color {
        switch self {
        case .low:
            .green
        case .medium:
            .orange
        case .high:
            .red
        }
    }
}

struct ScanItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let category: ScanCategory
    let risk: RiskLevel
    let canClean: Bool
    let bytes: Int64
    let isAccessible: Bool
}

struct CleanReport: Identifiable {
    var id = UUID()
    var cleanedAt: Date
    var results: [CleanResult]

    var releasedBytes: Int64 {
        results.filter(\.success).reduce(0) { $0 + $1.bytesBeforeClean }
    }

    var successCount: Int {
        results.filter(\.success).count
    }

    var failureCount: Int {
        results.filter { !$0.success }.count
    }
}

struct CleanResult: Identifiable {
    var id = UUID()
    var itemName: String
    var path: String
    var bytesBeforeClean: Int64
    var success: Bool
    var message: String
}

enum ScanCategory: String, CaseIterable, Identifiable {
    case browserCache
    case appCache
    case logs
    case downloads
    case trash
    case developerCache

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browserCache:
            "浏览器缓存"
        case .appCache:
            "App 缓存"
        case .logs:
            "日志与诊断"
        case .downloads:
            "下载大文件"
        case .trash:
            "废纸篓"
        case .developerCache:
            "开发缓存"
        }
    }

    var tint: Color {
        switch self {
        case .browserCache:
            .blue
        case .appCache:
            .purple
        case .logs:
            .teal
        case .downloads:
            .pink
        case .trash:
            .gray
        case .developerCache:
            .indigo
        }
    }
}

struct ScanSummary {
    let scannedAt: Date
    let items: [ScanItem]

    var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.bytes }
    }

    var cleanableBytes: Int64 {
        items.filter(\.canClean).reduce(0) { $0 + $1.bytes }
    }

    var groupedItems: [(category: ScanCategory, bytes: Int64, items: [ScanItem])] {
        ScanCategory.allCases.compactMap { category in
            let matches = items.filter { $0.category == category }
            guard !matches.isEmpty else { return nil }
            let bytes = matches.reduce(0) { $0 + $1.bytes }
            return (category, bytes, matches)
        }
        .sorted { $0.bytes > $1.bytes }
    }
}
