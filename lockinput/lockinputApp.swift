//
//  lockinputApp.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//
//  窗口版改动：不再占菜单栏右上角，改成普通窗口 App。
//  - 启动后显示一个普通窗口（居中、可拖动、可关闭）
//  - 关掉窗口即退出
//  - 点 Dock 图标 / 从访达再次打开 App 会把窗口叫回来
//  - 开机自启（登录项）拉起的启动不弹窗
//

import SwiftUI
import AppKit

@main
struct lockinputApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 界面全部由 AppDelegate 的 NSWindow 承载，这里只是 SwiftUI 要求的占位 scene
        Settings {
            EmptyView()
        }
        .commands {
            // 没有设置面板，去掉「设置…」菜单项
            CommandGroup(replacing: .appSettings) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    var inputManager = InputMethodManager.shared
    var languageManager = LanguageManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 普通 App：出现在 Dock / Cmd-Tab 里，而不是菜单栏右上角
        NSApp.setActivationPolicy(.regular)

        showMainWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 退出前把定时器 / 通知观察者清干净
        InputMethodManager.shared.teardown()
    }

    /// 点 Dock 图标、从访达再次打开 App 时，把窗口叫回来
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }

    @discardableResult
    private func showMainWindow() -> NSWindow {
        let window = self.window ?? makeMainWindow()
        window.makeKeyAndOrderFront(nil)
        return window
    }

    private func makeMainWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: ContentView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "LockInput"
        window.contentViewController = hosting
        window.isReleasedWhenClosed = false
        // 不让系统拿旧的状态恢复数据摆布窗口位置
        window.isRestorable = false

        // 让窗口刚好包住内容（和原版弹出面板观感一致），高度给个上下限兜底
        hosting.view.layoutSubtreeIfNeeded()
        let fitting = hosting.view.fittingSize
        window.setContentSize(NSSize(width: 280, height: min(max(fitting.height, 240), 520)))

        center(window)
        self.window = window
        return window
    }

    /// 按屏幕可视区域居中
    private func center(_ window: NSWindow) {
        guard let screen = NSScreen.main else {
            window.center()
            return
        }
        let visible = screen.visibleFrame
        var frame = window.frame
        frame.origin = NSPoint(
            x: visible.midX - frame.width / 2,
            y: visible.midY - frame.height / 2
        )
        window.setFrame(frame, display: false)
    }
}
