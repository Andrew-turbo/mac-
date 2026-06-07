# Mac 瘦身管家

一个面向 macOS 的本地存储分析与安全清理工具。

## 当前状态

项目已完成第一版产品规划、技术方案和 SwiftUI MVP 骨架。

当前 App 可以：

- 在仪表盘顶部显示 `UI v0.3` 标识，用来确认已经运行新版界面。
- 启动 macOS SwiftUI 窗口。
- 扫描常见系统数据相关目录。
- 展示总占用、可清理预估、扫描项目数量和最近扫描时间。
- 展示分类环形图和分类占比条。
- 展示扫描明细、风险等级和是否可清理。
- 勾选低风险清理项。
- 支持安全清理 / 深度清理模式切换。
- 清理前二次确认。
- 清理后展示清理报告。
- 左侧导航切换仪表盘、清理报告和设置。
- 设置系统数据提醒阈值，默认 150GB。
- 开关 macOS 桌面通知。
- 开关开发缓存扫描。
- 设置扫描排除路径。
- 使用项目内 App 图标和 accent color。
- 菜单栏常驻入口。
- 后台定时扫描，默认 60 分钟一次。
- 菜单栏快速查看占用、立即扫描、打开主窗口和退出。
- 清理结果写入本地日志，保留最近 100 次记录。

安全清理只会清理低风险项目。深度清理允许手动勾选“需确认”项目，高风险项目仍然只展示。

删除“需确认”项目的方式：切换到“深度清理”，手动勾选项目，点击“开始瘦身”，在确认弹窗里再次确认。

## 核心功能

- 系统数据相关空间仪表盘。
- 浏览器缓存、App 缓存、日志、下载大文件等分类扫描。
- 超过阈值提醒，默认 150GB。
- 用户确认后的一键瘦身。

## 文档

- [产品规划](docs/product-plan.md)
- [技术方案](docs/technical-plan.md)

## 其他 Mac 如何使用

这版适合通过 GitHub + 命令行分发。对方不需要安装完整 Xcode，也不需要你打包签名；只要是 macOS 14 或更新系统，并安装 Apple 命令行工具即可。

### 上传到 GitHub

在 GitHub 新建一个空仓库，建议仓库名使用：

```text
mac-slim-manager
```

不要勾选自动生成 README、`.gitignore` 或 License。创建后，在本项目目录执行：

```bash
git remote add origin https://github.com/guohuabao/mac-slim-manager.git
git push -u origin main
```

如果你的 GitHub 账号不是 `guohuabao`，把上面地址以及 `tools/install-and-run.sh` 里的 `guohuabao` 改成你的真实账号即可。上传完成后，把下面的一行命令发给其他 Mac 用户。

### 其他 Mac 运行

最便捷方式是直接复制这一行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/guohuabao/mac-slim-manager/main/tools/install-and-run.sh)"
```

这条命令会自动下载项目到 `~/.mac-slim-manager`，以后再次执行会先更新再启动。

如果对方电脑还没有 Apple 命令行工具，脚本会提示先运行：

```bash
xcode-select --install
```

安装完命令行工具后，再重新执行上面那条一行命令。

如果不想使用一行安装脚本，也可以手动运行：

```bash
git clone https://github.com/guohuabao/mac-slim-manager.git
cd mac-slim-manager
swift run MacSlimManager
```

如果扫描结果不完整，请在 macOS 的“系统设置 > 隐私与安全性”里给 Terminal、iTerm 或你使用的终端工具授予文件访问权限。清理前 App 会再次弹窗确认，不会在启动时自动删除文件。

## 图标

App 图标资源位于：

```text
AppProject/Assets.xcassets/AppIcon.appiconset
```

图标可以通过脚本重新生成：

```bash
swift tools/generate-app-icons.swift
```

## 运行

```bash
./tools/run.sh
```

如果菜单栏里已有旧版本正在运行，请先从菜单栏点击“退出”，再重新运行。新版仪表盘顶部会显示 `UI v0.3`。

也可以打开 Xcode 工程运行：

```bash
open MacSlimManager.xcodeproj
```

## 编译

```bash
swift build
```

Xcode 工程编译：

```bash
xcodebuild -project MacSlimManager.xcodeproj -scheme MacSlimManager -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## 下一步

1. 接入更细的缓存分类。
2. 增加清理日志历史列表和趋势图。
3. 增加清理前快照与可恢复机制。
