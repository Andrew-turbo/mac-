# Mac 瘦身管家技术方案

## 技术选型

第一版建议使用 Swift + SwiftUI 开发原生 macOS App。

原因：

- 更容易接入 macOS 文件系统、通知、菜单栏和权限。
- UI 性能稳定。
- 适合做本地工具，不依赖浏览器或云端。
- 后续可以自然扩展为菜单栏常驻 App。

当前项目同时保留两种构建入口：

- `Package.swift`：快速运行 SwiftUI 原型。
- `MacSlimManager.xcodeproj`：标准 macOS App 工程，用于后续应用图标、签名、权限、菜单栏常驻和发布配置。

## App 资源

当前 Xcode 工程已接入 `AppProject/Assets.xcassets`：

- `AppIcon.appiconset`：macOS App 图标。
- `AccentColor.colorset`：App accent color。

图标由 `tools/generate-app-icons.swift` 生成，后续调整品牌视觉时可以直接改脚本并重新生成。

## UI 结构

当前仪表盘采用三段结构：

- 顶部摘要区：系统数据相关占用、预计可释放、扫描项目、阈值和最近扫描时间。
- 中部分析区：分类环形图、分类占比条、清理计划。
- 底部复核区：逐项展示路径、大小、风险等级和是否默认清理。

清理计划已有 `安全清理` 和 `深度清理` 两种模式。安全清理只允许低风险项目；深度清理允许用户手动勾选中风险项目，高风险项目仍只展示。

## 签名与权限

当前工程包含 `AppProject/MacSlimManager.entitlements`，暂不启用 App Sandbox。

原因：

- 本工具需要扫描用户主目录下的缓存、日志、废纸篓和开发缓存。
- 沙盒会限制这类本地清理工具的文件访问能力。
- 如果后续需要上架 Mac App Store，应重新设计沙盒授权和用户选择目录流程。

## 架构

```text
MacSlimManager
├── App
│   └── App 入口
├── Models
│   ├── ScanCategory
│   ├── ScanItem
│   └── CleanResult
├── Services
│   ├── ScannerService
│   ├── CleanerService
│   ├── NotificationService
│   └── SettingsStore
├── Views
│   ├── DashboardView
│   ├── CategoryListView
│   ├── SettingsView
│   └── CleanReportView
└── Utilities
    ├── FileSizeFormatter
    └── DirectorySizer
```

## 扫描策略

扫描逻辑分两层：

1. 静态候选路径
   - 使用固定规则扫描常见缓存路径。
   - 适合浏览器缓存、日志、废纸篓、Xcode 缓存。

2. 目录枚举
   - 对 `~/Library/Caches` 做一级或二级枚举。
   - 汇总大目录，不深入展示每个小文件。

## 第一版候选路径

```text
~/Library/Caches
~/Library/Logs
~/Library/Logs/DiagnosticReports
~/Library/Developer/Xcode/DerivedData
~/Downloads
~/.Trash
```

浏览器缓存优先识别：

```text
~/Library/Caches/Google/Chrome
~/Library/Caches/com.apple.Safari
~/Library/Caches/Microsoft Edge
~/Library/Caches/Firefox
```

## 风险模型

```text
low
medium
high
```

- `low`：缓存类文件，可默认勾选。
- `medium`：需要用户确认。
- `high`：只展示，不进入一键清理。

## 清理策略

第一版清理只允许删除明确缓存目录中的内容，不删除目录本身，降低破坏 App 状态的风险。

当前已接入的安全清理规则：

- 只清理 `risk == low` 且 `canClean == true` 的项目。
- 清理时删除目录内部内容，保留目录本身。
- 深度清理模式允许用户手动勾选 `risk == medium` 且 `canClean == true` 的项目。
- 高风险项目和 `canClean == false` 的项目只展示，不参与一键瘦身。
- 清理前展示二次确认。
- 清理后展示清理报告。
- 清理结果写入 `~/Library/Application Support/MacSlimManager/clean-history.json`，保留最近 100 次记录。

清理前：

- 重新计算所选路径大小。
- 弹窗确认。
- 展示预计释放空间。

清理中：

- 逐项清理。
- 捕获错误。
- 写入清理结果。

清理后：

- 重新扫描。
- 展示释放空间。
- 展示失败项。

## 通知策略

MVP 阶段已实现 App 内提醒和手动开启的 macOS 桌面通知：

- 默认阈值：150GB。
- 阈值通过 `UserDefaults` 持久化。
- 当扫描总量超过阈值，在仪表盘顶部显示提醒。
- 用户在设置页开启桌面通知时，请求 macOS 通知权限。
- 开启通知后，扫描结果超过阈值会发送系统通知。
- 为避免频繁打扰，同一轮阈值提醒至少间隔 1 小时。

后续实现 macOS 通知：

- 允许用户设置提醒频率。

## 菜单栏与后台扫描

当前 App 已接入 SwiftUI `MenuBarExtra`：

- 菜单栏显示最近扫描总占用、可清理空间、阈值和最近扫描时间。
- 菜单栏支持立即扫描、打开主窗口和退出。
- App 打开后启动后台扫描循环。
- 默认后台扫描开启，间隔 60 分钟。
- 设置页可关闭后台扫描，或将间隔调整为 15 到 360 分钟。

后台扫描复用 `AppState` 的共享扫描逻辑，主窗口和菜单栏显示同一份结果。

## 权限与限制

第一版尽量只扫描用户主目录下可访问路径。

遇到无权限路径：

- 不弹系统级权限申请。
- 在结果里标记为无法访问。
- 提示用户后续可授权完整磁盘访问。

## 开发顺序

1. 创建 SwiftUI App 骨架。
2. 做静态 mock 数据仪表盘。
3. 实现目录大小计算。
4. 接入真实扫描。
5. 加入分类列表与风险等级。
6. 实现低风险清理。
7. 加入设置和阈值提醒。
8. 做菜单栏和通知。
