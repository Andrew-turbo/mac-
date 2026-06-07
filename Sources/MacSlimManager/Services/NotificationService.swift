import Foundation
import UserNotifications

struct NotificationService {
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func notifyStorageThresholdExceeded(totalBytes: Int64, thresholdGB: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "Mac 瘦身提醒"
        content.body = "系统数据相关占用已达到 \(StorageFormatter.string(from: totalBytes))，超过你设置的 \(Int(thresholdGB))GB 阈值。"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "storage-threshold-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
