import AppKit
import ApplicationServices
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    /// 本次运行是否已弹过授权提示（避免反复打扰）
    private var hasPromptedForPermission = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // 仅菜单栏，不占 Dock

        setupMenuBar()

        HotKeyManager.shared.onHotKey = { [weak self] in
            self?.performTranslate()
        }
        registerHotKey()

        // 监听辅助功能权限变化：一旦用户在系统设置里授权，立刻感知
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(accessibilityTrustDidChange),
            name: NSNotification.Name("AXTrustedStatusDidChange"),
            object: nil
        )

        // 首次启动若没有辅助功能权限，引导授权（只弹一次）
        if !AXIsProcessTrusted() {
            promptAccessibilityPermission()
        }
    }

    @objc private func accessibilityTrustDidChange() {
        if AXIsProcessTrusted() {
            PopupController.shared.showMessage("辅助功能权限已开启 ✓\n选中文本后按 \(HotKeyManager.shared.currentDisplay) 即可翻译")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }

    // MARK: - 菜单栏

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "character.book.closed",
                                   accessibilityDescription: "FastTranslate")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "划词翻译  \(HotKeyManager.shared.currentDisplay)",
                                action: #selector(performTranslate), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "辅助功能权限…", action: #selector(checkPermission), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 FastTranslate", action: #selector(quitApp), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
    }

    // MARK: - 动作

    @objc private func performTranslate() {
        guard AXIsProcessTrusted() else {
            promptAccessibilityPermission()
            return
        }

        guard let info = SelectionReader.readSelection(), !info.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            PopupController.shared.showMessage("未检测到选中文本")
            return
        }

        PopupController.shared.show(original: info.text, anchorBounds: info.bounds)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "FastTranslate 设置"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 440, height: 460))
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.center()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func checkPermission() {
        if AXIsProcessTrusted() {
            PopupController.shared.showMessage("辅助功能权限已开启 ✓\n选中文本后按 \(HotKeyManager.shared.currentDisplay) 即可翻译")
        } else {
            hasPromptedForPermission = false // 手动点击时允许再弹授权引导
            promptAccessibilityPermission()
        }
    }

    // MARK: - 快捷键

    private func registerHotKey() {
        HotKeyManager.shared.register(keyCode: Config.hotKeyCode, modifiers: Config.hotKeyModifiers)
    }

    // MARK: - 权限

    private func promptAccessibilityPermission() {
        // 本次运行已弹过模态提示就不再弹，改为轻提示，避免反复打扰
        guard !hasPromptedForPermission else {
            PopupController.shared.showMessage("需要辅助功能权限\n请在 系统设置 → 隐私与安全性 → 辅助功能 中勾选 FastTranslate")
            return
        }
        hasPromptedForPermission = true

        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "FastTranslate 需要「辅助功能」权限来读取你选中的文本。\n\n请点击「打开设置」，然后在 系统设置 → 隐私与安全性 → 辅助功能 中勾选 FastTranslate。\n（若未列出，先关闭再打开，或重新启动 App）"
        alert.addButton(withTitle: "打开设置")
        alert.addButton(withTitle: "稍后再说")
        if alert.runModal() == .alertFirstButtonReturn {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}
