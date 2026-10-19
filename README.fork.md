# LockInput 窗口版（个人 fork）

基于 [bigccc/inputlock](https://github.com/bigccc/inputlock) v1.1.1 改的一个本地版本：
**不要菜单栏右上角的图标，改成点 App 弹一个普通窗口。**

## 改了什么

| 项目 | 原版 | 本 fork |
| --- | --- | --- |
| 入口 | 菜单栏图标（`NSStatusItem`）+ 弹出面板（`NSPopover`） | 普通窗口（`NSWindow`） |
| 是否常驻菜单栏 | 是（`LSUIElement = true`） | 否（`LSUIElement = NO`，出现在 Dock / Cmd-Tab） |
| 窗口 | 贴在菜单栏图标下方 | 屏幕中间、可拖动 / 最小化 / 关闭 |
| 关窗口 | — | App 不退出，锁定继续生效；点 Dock 图标把窗口叫回来 |
| 图标 | 仓库里是空占位，显示系统默认图标 | 补了一个蓝色锁形 `AppIcon.icns` |

核心逻辑一行没动：`InputMethodManager` 仍然用 Carbon TIS API 读/切输入法、监听
「输入法切换」通知、锁定时每 0.35 秒兜底切回；开机自启、多语言、启动后恢复锁定都保留。

## 构建 / 测试

```bash
# 构建（产物在 build/Build/Products/Release/lockinput.app）
xcodebuild -project lockinput.xcodeproj -scheme lockinput -configuration Release -derivedDataPath build build

# 单元测试（8 项）
xcodebuild test -project lockinput.xcodeproj -scheme lockinput -destination 'platform=macOS'
```

## 安装

1. 先退出原版（菜单栏图标 → 右键 → 退出）
2. 把 `build/Build/Products/Release/lockinput.app` 拖进 `/Applications`，覆盖同名 App
3. 双击启动；关掉窗口后 App 仍在 Dock 里，点图标即可重新打开

回滚原版：把 `lockinput-original-1.1.1.app`（工作区根目录的备份）拖回 `/Applications/lockinput.app` 即可。

## 推到自己的 GitHub fork

```bash
# 网页点 Fork，或：
gh repo fork bigccc/inputlock --clone=false

# 让本地指向自己的 fork
git remote rename origin upstream
git remote add origin git@github.com:<你的用户名>/inputlock.git
git push -u origin main
git push -u origin feature/window-app
```

## 注意事项

- **未公证 / ad-hoc 签名**：和原版一样，首次启动可能被 Gatekeeper 拦，右键 →「打开」放行。每次改版本都要重新放行。
- **开机自启**：这个改动后 App 变成普通窗口 App，登录自启时会顺带弹出窗口（macOS 没有可靠的「是否为登录启动」判定，试过 `NSApplication.launchIsDefaultUserInfoKey`，在状态恢复场景下会误判，所以没做隐藏启动）。
- **Dock 图标缓存**：替换 App 后如果 Dock 还显示旧图标，执行 `killall Dock` 即可。
- 别和「按 App 自动切输入源」的工具（如 Input Source Pro）同时开，两者会互相把输入法拉回去。
- 窗口高度按内容自动算（`fittingSize`，带 240–520pt 的上下限），输入源多时列表区域最多 180pt、内部滚动。
