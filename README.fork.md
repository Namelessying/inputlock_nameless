# LockInput 窗口版（个人 fork）

基于 [bigccc/inputlock](https://github.com/bigccc/inputlock) v1.1.1 改的一个个人版本：
**不要菜单栏右上角的图标，改成点 App 弹一个普通窗口。**

本仓库：<https://github.com/Namelessying/inputlock_nameless>

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

## 内存泄漏排查

用 `leaks` 和高频操作压测过，结果：

- `leaks` 报告 **0 leaks / 0 leaked bytes**
- 连续 30 次关窗/开窗、30 次锁定/解锁、20 次 App 切换后，RSS 稳定在 **99–104 MB**，
  Physical footprint 稳定在 **29–30 MB**（RSS 里有大量和其他 App 共享的框架页，不是私有内存）
- 结论：没有发现真正的泄漏；下面这些是防御式加固，避免以后改坏

加固点：

1. `InputMethodManager.teardown()`：统一停掉两个 `Timer` 并移除 3 组通知观察者，
   由 `applicationWillTerminate` 调用；`deinit` 也走同一条路径
2. `loadAvailableInputSources()` / `enforceLockedInputSource()` 包 `autoreleasepool`：
   TIS 枚举会造一批 CF 对象，0.35 秒一次的兜底循环里避免在同一个 runloop 里堆积
3. `LanguageManager` 不再重复赋值同一个 `Bundle`，并去掉多余的 `objectWillChange.send()`
   （`@Published` 本身会发通知，之前等于每次切语言多刷一轮 UI）
4. 定时器与延迟回调仍全部 `[weak self]`，不会形成 self ↔ Timer 的循环引用

## 推到 GitHub

仓库已经推到这里：<https://github.com/Namelessying/inputlock_nameless>

```bash
git remote -v
# origin    git@github.com:Namelessying/inputlock_nameless.git
# upstream  https://github.com/bigccc/inputlock.git

git push origin main
git push origin feature/window-app
```

## 注意事项

- **未公证 / ad-hoc 签名**：和原版一样，首次启动可能被 Gatekeeper 拦，右键 →「打开」放行。每次改版本都要重新放行。
- **开机自启**：这个改动后 App 变成普通窗口 App，登录自启时会顺带弹出窗口（macOS 没有可靠的「是否为登录启动」判定，试过 `NSApplication.launchIsDefaultUserInfoKey`，在状态恢复场景下会误判，所以没做隐藏启动）。
- **Dock 图标缓存**：替换 App 后如果 Dock 还显示旧图标，执行 `killall Dock` 即可。
- 别和「按 App 自动切输入源」的工具（如 Input Source Pro）同时开，两者会互相把输入法拉回去。
- 窗口高度按内容自动算（`fittingSize`，带 240–520pt 的上下限），输入源多时列表区域最多 180pt、内部滚动。
