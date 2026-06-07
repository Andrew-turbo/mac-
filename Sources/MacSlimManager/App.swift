import AppKit
import SwiftUI

@main
struct MacSlimManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @State private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup(id: "main") {
            DashboardView(appState: appState, settings: settings)
                .frame(minWidth: 920, minHeight: 640)
                .task {
                    appState.startBackgroundScanning(settings: settings)
                }
        }
        .windowStyle(.titleBar)

        MenuBarExtra {
            MenuBarContent(
                appState: appState,
                settings: settings,
                onScanNow: {
                    Task { await appState.runScan(settings: settings) }
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
        } label: {
            HStack(spacing: 6) {
                if let image = AppIconLoader.projectIconImage() {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "internaldrive")
                }
                Text("Mac 瘦身管家")
            }
            .task {
                appState.startBackgroundScanning(settings: settings)
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let image = AppIconLoader.projectIconImage() {
            NSApp.applicationIconImage = image
        }
    }
}

enum AppIconLoader {
    static func projectIconImage() -> NSImage? {
        let projectIconPath = URL(filePath: FileManager.default.currentDirectoryPath)
            .appending(path: "AppProject/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")

        return NSImage(contentsOf: projectIconPath)
    }
}

private struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    let appState: AppState
    let settings: SettingsStore
    let onScanNow: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            if let summary = appState.summary {
                Text("相关占用：\(StorageFormatter.string(from: summary.totalBytes))")
                Text("可清理：\(StorageFormatter.string(from: summary.cleanableBytes))")
                Text("阈值：\(Int(settings.thresholdGB))GB")

                if summary.totalBytes >= settings.thresholdBytes {
                    Label("已超过阈值", systemImage: "exclamationmark.triangle.fill")
                }

                Text("最近扫描：\(summary.scannedAt.formatted(date: .omitted, time: .shortened))")
            } else {
                Text("还没有扫描结果")
            }

            Divider()

            Button(appState.isScanning ? "扫描中" : "立即扫描", action: onScanNow)
                .disabled(appState.isScanning)
            Button("打开主窗口") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Text(settings.backgroundScanningEnabled ? "后台扫描：开启" : "后台扫描：关闭")
            Text("间隔：\(Int(settings.backgroundScanIntervalMinutes)) 分钟")

            Divider()

            Button("退出", action: onQuit)
        }
    }
}
