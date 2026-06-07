import SwiftUI

struct DashboardView: View {
    let appState: AppState
    let settings: SettingsStore

    @State private var selection: AppSection? = .dashboard
    @State private var cleanMode: CleanMode = .safe
    @State private var selectedItems = Set<UUID>()
    @State private var showCleanConfirmation = false
    @State private var notificationAuthorizationMessage: String?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .alert("确认一键瘦身", isPresented: $showCleanConfirmation) {
            Button("取消", role: .cancel) {}
            Button("开始清理", role: .destructive) {
                Task { await runClean() }
            }
        } message: {
            Text(cleanConfirmationMessage)
        }
        .sheet(item: Binding(get: { appState.cleanReport }, set: { appState.cleanReport = $0 })) { report in
            CleanReportView(report: report)
        }
        .onChange(of: appState.summary?.scannedAt) {
            selectedItems = Set(appState.summary?.items.filter { isDefaultSelected($0) }.map(\.id) ?? [])
        }
        .onChange(of: cleanMode) {
            if cleanMode == .safe {
                selectedItems = Set(appState.summary?.items.filter { isDefaultSelected($0) }.map(\.id) ?? [])
            }
        }
    }

    private var sidebar: some View {
        List(AppSection.allCases, selection: $selection) { section in
            Label(section.title, systemImage: section.systemImage)
                .tag(section)
        }
        .navigationSplitViewColumnWidth(190)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .dashboard {
        case .dashboard:
            dashboard
        case .report:
            ReportHistoryView(report: appState.cleanReport)
        case .settings:
            SettingsView(
                settings: settings,
                notificationMessage: notificationAuthorizationMessage,
                onRequestNotificationPermission: requestNotificationPermission,
                onSettingsChanged: {
                    Task { await runScan() }
                }
            )
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let summary = appState.summary {
                    hero(summary)
                    alertIfNeeded(summary)

                    HStack(alignment: .top, spacing: 18) {
                        categoryOverview(summary)
                            .frame(minWidth: 320, maxWidth: 420)
                        cleaningPlan(summary)
                    }

                    itemList(summary)
                } else {
                    emptyHero
                    placeholder
                }
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.cyan.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mac 瘦身管家")
                    .font(.largeTitle.bold())
                Text("看懂系统数据，占用过高时提醒，并优先清理低风险缓存。")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await runScan() }
            } label: {
                Label(appState.isScanning ? "扫描中" : "重新扫描", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isScanning)
        }
    }

    private func hero(_ summary: ScanSummary) -> some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                heroTitle

                VStack(alignment: .leading, spacing: 6) {
                    Text(StorageFormatter.string(from: summary.totalBytes))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("系统数据相关占用")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                thresholdStrip(summary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                StatPill(title: "预计可释放", value: StorageFormatter.string(from: selectedCleanableBytes), systemImage: "sparkles", tint: .green)
                StatPill(title: "扫描项目", value: "\(summary.items.count)", systemImage: "folder", tint: .blue)
                StatPill(title: "阈值", value: "\(Int(settings.thresholdGB))GB", systemImage: "bell", tint: .orange)
                StatPill(title: "最近扫描", value: summary.scannedAt.formatted(date: .omitted, time: .shortened), systemImage: "clock", tint: .purple)
            }
            .frame(width: 220)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor),
                    Color.blue.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.cyan)
                .frame(width: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var emptyHero: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                heroTitle

                VStack(alignment: .leading, spacing: 6) {
                    Text("准备扫描")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("新版仪表盘会展示分类环形图、清理计划和复核清单。")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                Task { await runScan() }
            } label: {
                Label(appState.isScanning ? "扫描中" : "开始扫描", systemImage: "play.fill")
                    .frame(width: 140)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(appState.isScanning)
        }
        .padding(24)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.cyan)
                .frame(width: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var heroTitle: some View {
        HStack(spacing: 10) {
            if let image = AppIconLoader.projectIconImage() {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 42, height: 42)
            } else {
                Image(systemName: "internaldrive")
                    .font(.system(size: 34))
                    .foregroundStyle(.cyan)
                    .frame(width: 42, height: 42)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Mac 瘦身管家")
                        .font(.largeTitle.bold())
                    Text("UI v0.3")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.16))
                        .foregroundStyle(.cyan)
                        .clipShape(Capsule())
                }
                Text("本地扫描系统数据相关目录，优先清理低风险缓存。")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func thresholdStrip(_ summary: ScanSummary) -> some View {
        let ratio = min(1, Double(summary.totalBytes) / Double(settings.thresholdBytes))

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.totalBytes >= settings.thresholdBytes ? "已超过提醒阈值" : "低于提醒阈值")
                    .font(.headline)
                Spacer()
                Text("\(Int(ratio * 100))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .windowBackgroundColor))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(summary.totalBytes >= settings.thresholdBytes ? Color.orange : Color.green)
                        .frame(width: max(8, proxy.size.width * ratio))
                }
            }
            .frame(height: 12)
        }
    }

    private func alertIfNeeded(_ summary: ScanSummary) -> some View {
        Group {
            if summary.totalBytes >= settings.thresholdBytes {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("系统数据相关占用已超过 \(Int(settings.thresholdGB))GB，建议检查可清理项。")
                        .font(.headline)
                    Spacer()
                }
                .padding(14)
                .background(.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func categoryOverview(_ summary: ScanSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("分类占比")
                    .font(.title2.bold())
                Spacer()
                Text("\(summary.groupedItems.count) 类")
                    .foregroundStyle(.secondary)
            }

            DonutChart(groups: summary.groupedItems, totalBytes: summary.totalBytes)
                .frame(height: 220)

            ForEach(summary.groupedItems, id: \.category.id) { group in
                let percent = summary.totalBytes > 0 ? Double(group.bytes) / Double(summary.totalBytes) : 0
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(group.category.title, systemImage: "circle.fill")
                            .foregroundStyle(group.category.tint)
                        Spacer()
                        Text(StorageFormatter.string(from: group.bytes))
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.quaternary)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(group.category.tint)
                                .frame(width: max(8, proxy.size.width * percent))
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
        .panel()
    }

    private func cleaningPlan(_ summary: ScanSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("清理计划")
                    .font(.title2.bold())
                Spacer()
                Picker("", selection: $cleanMode) {
                    ForEach(CleanMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(cleanMode.subtitle)
                    .font(.headline)
                Text(cleanMode.description)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                PlanMetric(title: "已选择", value: "\(selectedCleanableItems.count) 项", tint: .blue)
                PlanMetric(title: "预计释放", value: StorageFormatter.string(from: selectedCleanableBytes), tint: .green)
                PlanMetric(title: "需确认", value: "\(summary.items.filter { $0.canClean && $0.risk == .medium }.count) 项", tint: .orange)
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: cleanMode == .safe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(cleanMode == .safe ? .green : .orange)
                Text(cleanMode == .safe ? "当前只会清理低风险缓存。" : "可手动勾选需确认项目；高风险项目仍只展示。")
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Button {
                showCleanConfirmation = true
            } label: {
                Label(appState.isCleaning ? "清理中" : "开始瘦身", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCleanableItems.isEmpty || appState.isScanning || appState.isCleaning)
        }
        .panel()
    }

    private func itemList(_ summary: ScanSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("清理清单")
                    .font(.title2.bold())
                Spacer()
                Text("逐项复核路径、大小和风险等级")
                    .foregroundStyle(.secondary)
            }

            if selectedCleanableBytes > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("已选择 \(selectedCleanableItems.count) 项，预计释放 \(StorageFormatter.string(from: selectedCleanableBytes))")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("项目").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("类型").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("大小").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("风险").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("状态").font(.caption.bold()).foregroundStyle(.secondary)
                }

                Divider()
                    .gridCellColumns(6)

                ForEach(summary.items) { item in
                    cleanerRow(item)
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func cleanerRow(_ item: ScanItem) -> some View {
        GridRow {
            Toggle("", isOn: binding(for: item))
                .labelsHidden()
                .disabled(!isSelectable(item) || appState.isCleaning)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: item.category.systemImage)
                        .foregroundStyle(item.category.tint)
                    Text(item.name)
                        .fontWeight(.medium)
                }
                Text(item.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(item.category.title)

            Text(StorageFormatter.string(from: item.bytes))
                .monospacedDigit()

            Label(item.risk.title, systemImage: item.risk.systemImage)
                .foregroundStyle(item.risk.color)

            Text(statusText(for: item))
                .foregroundStyle(statusColor(for: item))
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("正在扫描常见系统数据目录")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private func runScan() async {
        await appState.runScan(settings: settings)
        selectedItems = Set(appState.summary?.items.filter { isDefaultSelected($0) }.map(\.id) ?? [])
    }

    private func runClean() async {
        await appState.runClean(
            items: selectedCleanableItems,
            settings: settings,
            allowMediumRisk: cleanMode == .deep
        )
    }

    private var selectedCleanableItems: [ScanItem] {
        guard let summary = appState.summary else { return [] }
        return summary.items.filter { item in
            isSelectable(item) && selectedItems.contains(item.id)
        }
    }

    private var selectedMediumRiskItems: [ScanItem] {
        selectedCleanableItems.filter { $0.risk == .medium }
    }

    private var selectedCleanableBytes: Int64 {
        selectedCleanableItems.reduce(0) { $0 + $1.bytes }
    }

    private var cleanConfirmationMessage: String {
        let base = "将清理 \(selectedCleanableItems.count) 个项目，预计释放 \(StorageFormatter.string(from: selectedCleanableBytes))。清理会删除所选目录中的内容，但保留目录本身。"

        guard !selectedMediumRiskItems.isEmpty else {
            return base
        }

        return base + " 其中包含 \(selectedMediumRiskItems.count) 个需确认项目，请确认这些 App 或工具当前没有在运行。"
    }

    private func isSelectable(_ item: ScanItem) -> Bool {
        item.canClean && (item.risk == .low || (cleanMode == .deep && item.risk == .medium))
    }

    private func isDefaultSelected(_ item: ScanItem) -> Bool {
        item.canClean && item.risk == .low
    }

    private func statusText(for item: ScanItem) -> String {
        guard item.canClean else {
            return "仅展示"
        }

        return switch item.risk {
        case .low:
            "默认清理"
        case .medium:
            cleanMode == .deep ? "可勾选" : "切到深度"
        case .high:
            "仅展示"
        }
    }

    private func statusColor(for item: ScanItem) -> Color {
        guard item.canClean else {
            return .secondary
        }

        return switch item.risk {
        case .low:
            .green
        case .medium:
            cleanMode == .deep ? .orange : .secondary
        case .high:
            .secondary
        }
    }

    private func binding(for item: ScanItem) -> Binding<Bool> {
        Binding {
            selectedItems.contains(item.id)
        } set: { isSelected in
            if isSelected {
                if isSelectable(item) {
                    selectedItems.insert(item.id)
                }
            } else {
                selectedItems.remove(item.id)
            }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let granted = await appState.requestNotificationPermission(settings: settings)
            notificationAuthorizationMessage = granted ? "桌面通知已开启" : "通知权限未开启，可在系统设置中允许通知"
        }
    }
}

private enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case report
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            "仪表盘"
        case .report:
            "清理报告"
        case .settings:
            "设置"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "gauge.with.dots.needle.bottom.50percent"
        case .report:
            "doc.text.magnifyingglass"
        case .settings:
            "gearshape"
        }
    }
}

private enum CleanMode: String, CaseIterable, Identifiable {
    case safe
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safe:
            "安全清理"
        case .deep:
            "深度清理"
        }
    }

    var subtitle: String {
        switch self {
        case .safe:
            "低风险缓存优先"
        case .deep:
            "更广范围，逐项确认"
        }
    }

    var description: String {
        switch self {
        case .safe:
            "默认只选择浏览器缓存、诊断报告等可自动重建的内容。"
        case .deep:
            "展示 App 缓存、废纸篓、开发缓存等中风险项目，但暂不自动勾选。"
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PlanMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct DonutChart: View {
    let groups: [(category: ScanCategory, bytes: Int64, items: [ScanItem])]
    let totalBytes: Int64

    var body: some View {
        ZStack {
            Canvas { context, size in
                let diameter = min(size.width, size.height)
                let rect = CGRect(
                    x: (size.width - diameter) / 2,
                    y: (size.height - diameter) / 2,
                    width: diameter,
                    height: diameter
                ).insetBy(dx: 18, dy: 18)

                var startAngle = Angle.degrees(-90)

                if totalBytes == 0 {
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(.gray.opacity(0.25)),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    return
                }

                for group in groups {
                    let fraction = Double(group.bytes) / Double(totalBytes)
                    let endAngle = startAngle + .degrees(360 * fraction)
                    var path = Path()
                    path.addArc(
                        center: CGPoint(x: rect.midX, y: rect.midY),
                        radius: rect.width / 2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    context.stroke(
                        path,
                        with: .color(group.category.tint),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    startAngle = endAngle
                }
            }

            VStack(spacing: 4) {
                Text(StorageFormatter.string(from: totalBytes))
                    .font(.title2.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("总占用")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SettingsView: View {
    let settings: SettingsStore
    let notificationMessage: String?
    let onRequestNotificationPermission: () -> Void
    let onSettingsChanged: () -> Void

    @State private var excludedPathInput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("设置")
                        .font(.largeTitle.bold())
                    Text("调整提醒阈值、桌面通知和扫描范围。")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("提醒阈值")
                        .font(.title2.bold())

                    HStack {
                        Slider(
                            value: Binding(
                                get: { settings.thresholdGB },
                                set: {
                                    settings.thresholdGB = $0
                                    onSettingsChanged()
                                }
                            ),
                            in: 50...500,
                            step: 10
                        )
                        Text("\(Int(settings.thresholdGB))GB")
                            .font(.title3.bold())
                            .monospacedDigit()
                            .frame(width: 90, alignment: .trailing)
                    }

                    Text("当系统数据相关占用超过该阈值时，仪表盘会显示提醒。")
                        .foregroundStyle(.secondary)
                }
                .settingsPanel()

                VStack(alignment: .leading, spacing: 16) {
                    Text("桌面通知")
                        .font(.title2.bold())

                    Toggle(
                        "超过阈值时发送 macOS 通知",
                        isOn: Binding(
                            get: { settings.desktopNotificationsEnabled },
                            set: { isEnabled in
                                if isEnabled {
                                    onRequestNotificationPermission()
                                } else {
                                    settings.desktopNotificationsEnabled = false
                                }
                            }
                        )
                    )

                    if let notificationMessage {
                        Text(notificationMessage)
                            .foregroundStyle(.secondary)
                    }
                }
                .settingsPanel()

                VStack(alignment: .leading, spacing: 16) {
                    Text("扫描范围")
                        .font(.title2.bold())

                    Toggle(
                        "包含开发缓存",
                        isOn: Binding(
                            get: { settings.scanDeveloperCaches },
                            set: {
                                settings.scanDeveloperCaches = $0
                                onSettingsChanged()
                            }
                        )
                    )

                    Text("开启后会统计 Xcode DerivedData 等开发缓存。")
                        .foregroundStyle(.secondary)
                }
                .settingsPanel()

                VStack(alignment: .leading, spacing: 16) {
                    Text("排除路径")
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        TextField("例如 ~/Library/Caches/SomeApp", text: $excludedPathInput)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            settings.addExcludedPath(excludedPathInput)
                            excludedPathInput = ""
                            onSettingsChanged()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .help("添加排除路径")
                        .disabled(excludedPathInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if settings.excludedPaths.isEmpty {
                        Text("当前没有排除路径。")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(settings.excludedPaths, id: \.self) { path in
                                HStack(spacing: 8) {
                                    Text(path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    Spacer()

                                    Button {
                                        settings.removeExcludedPath(path)
                                        onSettingsChanged()
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("移除排除路径")
                                }
                            }
                        }
                    }

                    Text("扫描时会跳过这些目录及其子目录，适合排除你不想统计或不想清理的 App 缓存。")
                        .foregroundStyle(.secondary)
                }
                .settingsPanel()

                VStack(alignment: .leading, spacing: 16) {
                    Text("后台扫描")
                        .font(.title2.bold())

                    Toggle(
                        "开启菜单栏后台扫描",
                        isOn: Binding(
                            get: { settings.backgroundScanningEnabled },
                            set: { settings.backgroundScanningEnabled = $0 }
                        )
                    )

                    HStack {
                        Slider(
                            value: Binding(
                                get: { settings.backgroundScanIntervalMinutes },
                                set: { settings.backgroundScanIntervalMinutes = $0 }
                            ),
                            in: 15...360,
                            step: 15
                        )
                        Text("\(Int(settings.backgroundScanIntervalMinutes)) 分钟")
                            .font(.title3.bold())
                            .monospacedDigit()
                            .frame(width: 110, alignment: .trailing)
                    }

                    Text("App 打开后会按该间隔自动扫描；超过阈值且已开启通知时，会发送桌面提醒。")
                        .foregroundStyle(.secondary)
                }
                .settingsPanel()
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ReportHistoryView: View {
    let report: CleanReport?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("清理报告")
                        .font(.largeTitle.bold())
                    Text("查看最近一次清理结果。")
                        .foregroundStyle(.secondary)
                }

                if let report {
                    CleanReportContent(report: report)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("还没有清理报告")
                            .font(.title3.bold())
                        Text("完成一次一键瘦身后，这里会显示结果。")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private extension View {
    func panel() -> some View {
        padding(18)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    func settingsPanel() -> some View {
        padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private extension ScanCategory {
    var systemImage: String {
        switch self {
        case .browserCache:
            "safari"
        case .appCache:
            "app.dashed"
        case .logs:
            "doc.text"
        case .downloads:
            "arrow.down.circle"
        case .trash:
            "trash"
        case .developerCache:
            "hammer"
        }
    }
}

private extension RiskLevel {
    var systemImage: String {
        switch self {
        case .low:
            "checkmark.circle"
        case .medium:
            "exclamationmark.circle"
        case .high:
            "eye"
        }
    }
}

private struct CleanReportView: View {
    @State private var report: CleanReport

    init(report: CleanReport) {
        _report = State(initialValue: report)
    }

    var body: some View {
        CleanReportContent(report: report)
            .padding(24)
            .frame(minWidth: 640, minHeight: 460)
    }
}

private struct CleanReportContent: View {
    @State private var report: CleanReport

    init(report: CleanReport) {
        _report = State(initialValue: report)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("清理报告")
                        .font(.title.bold())
                    Text(report.cleanedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(StorageFormatter.string(from: report.releasedBytes))
                        .font(.title.bold())
                    Text("本次释放")
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                MetricCard(title: "成功项目", value: "\(report.successCount)", systemImage: "checkmark.circle")
                MetricCard(title: "失败项目", value: "\(report.failureCount)", systemImage: "xmark.circle")
            }

            List {
                ForEach($report.results, id: \.id) { result in
                    let value = result.wrappedValue
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: value.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(value.success ? .green : .red)
                            Text(value.itemName)
                                .fontWeight(.medium)
                            Spacer()
                            Text(StorageFormatter.string(from: value.bytesBeforeClean))
                                .foregroundStyle(.secondary)
                        }

                        Text(value.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(value.message)
                            .font(.caption)
                            .foregroundStyle(value.success ? Color.secondary : Color.red)
                    }
                    .padding(.vertical, 6)
                }
            }
            .frame(minHeight: 260)
        }
    }
}
