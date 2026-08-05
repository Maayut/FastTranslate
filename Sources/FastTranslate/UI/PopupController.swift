import AppKit
import SwiftUI

/// 翻译结果浮动弹窗：非激活（不抢焦点）、悬浮在所有窗口之上
/// 说明：仅在主线程使用（快捷键回调/App 生命周期均在主线程），因此不标注 MainActor
final class PopupController: NSObject, NSWindowDelegate {
    static let shared = PopupController()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?

    private override init() {}

    /// 翻译弹窗
    func show(original: String, anchorBounds: CGRect?) {
        hide()
        let view = PopupView(original: original) { [weak self] in self?.hide() }
        present(rootView: AnyView(view), width: 400, height: 250, anchorBounds: anchorBounds)
    }

    /// 纯消息弹窗（如"未检测到选中文本"）
    func showMessage(_ message: String) {
        hide()
        let view = MessageView(message: message) { [weak self] in self?.hide() }
        present(rootView: AnyView(view), width: 320, height: 110, anchorBounds: nil)
    }

    func hide() {
        removeDismissMonitors()
        panel?.orderOut(nil)
        hostingView = nil
    }

    // MARK: - 弹窗创建与定位

    private func present(rootView: AnyView, width: CGFloat, height: CGFloat, anchorBounds: CGRect?) {
        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.level = .floating
            p.isFloatingPanel = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.hidesOnDeactivate = false
            p.isReleasedWhenClosed = false
            p.delegate = self
            panel = p
        }
        guard let panel else { return }

        let host = NSHostingView(rootView: rootView)
        host.autoresizingMask = [.width, .height]
        hostingView = host
        panel.contentView = host
        panel.setContentSize(NSSize(width: width, height: height))

        position(panel: panel, size: NSSize(width: width, height: height), anchorBounds: anchorBounds)
        installDismissMonitors()
        panel.orderFrontRegardless()
    }

    // MARK: - 自动消失（失焦 / 点击别处 / 切换页面）

    private func installDismissMonitors() {
        guard globalClickMonitor == nil, localClickMonitor == nil else { return }

        // 1) 点击其他应用任意位置 → 关闭
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async { self?.hide() }
        }

        // 2) 点击本应用内、弹窗外区域 → 关闭（弹窗内点击按钮不受影响）
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel else { return event }
            if let window = event.window {
                let screenPoint = window.convertPoint(toScreen: event.locationInWindow)
                if !panel.frame.contains(screenPoint) {
                    self.hide()
                }
            }
            return event
        }

        // 3) 切换到其他应用（Cmd+Tab / 点击其他 App）→ 关闭
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeAppDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func activeAppDidChange(_ note: Notification) {
        if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           app.bundleIdentifier == Bundle.main.bundleIdentifier {
            return // 激活的是自己（如打开设置窗口），不关闭
        }
        hide()
    }

    private func removeDismissMonitors() {
        if let m = globalClickMonitor {
            NSEvent.removeMonitor(m)
            globalClickMonitor = nil
        }
        if let m = localClickMonitor {
            NSEvent.removeMonitor(m)
            localClickMonitor = nil
        }
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    // MARK: - 定位

    private func position(panel: NSPanel, size: NSSize, anchorBounds: CGRect?) {
        var origin: NSPoint

        if let anchorBounds, !anchorBounds.isNull, anchorBounds.width > 0, anchorBounds.height > 0 {
            // AX 坐标：全局坐标系，左上角原点
            // AppKit 窗口坐标：主屏左下角为原点
            guard let screen = screenContaining(anchorBounds) else {
                origin = NSPoint(x: NSScreen.main!.frame.midX - size.width / 2,
                                 y: NSScreen.main!.frame.midY - size.height / 2)
                panel.setFrameOrigin(origin)
                return
            }
            let axY = anchorBounds.midY
            let appKitY = screen.frame.maxY - axY
            origin = NSPoint(x: anchorBounds.midX - size.width / 2,
                             y: appKitY - size.height - 12) // 显示在选区下方
        } else {
            let mouse = NSEvent.mouseLocation
            origin = NSPoint(x: mouse.x - size.width / 2, y: mouse.y - size.height - 24)
        }

        // 限制在屏幕内
        if let screen = NSScreen.screenContainingPoint(origin, size: size) {
            let f = screen.frame
            origin.x = min(max(origin.x, f.minX + 8), f.maxX - size.width - 8)
            origin.y = min(max(origin.y, f.minY + 8), f.maxY - size.height - 8)
        }
        panel.setFrameOrigin(origin)
    }

    /// 选区在哪个屏幕（AX 坐标 → 主屏 AppKit 坐标）
    private func screenContaining(_ bounds: CGRect) -> NSScreen? {
        for screen in NSScreen.screens {
            let top = screen.frame.maxY // 该屏幕顶部（AppKit Y）
            let bottom = screen.frame.minY
            let axTop = NSScreen.main?.frame.maxY ?? screen.frame.maxY
            // 该屏幕在 AX 坐标系下的竖直范围
            let axScreenMin = axTop - top
            let axScreenMax = axTop - bottom
            if bounds.midY >= axScreenMin - 1 && bounds.midY <= axScreenMax + 1 {
                return screen
            }
        }
        return NSScreen.main
    }
}

extension NSScreen {
    static func screenContainingPoint(_ point: NSPoint, size: NSSize) -> NSScreen? {
        NSScreen.screens.first { $0.frame.insetBy(dx: -8, dy: -8).contains(CGRect(origin: point, size: size)) }
            ?? NSScreen.screens.first { $0.frame.contains(point) }
            ?? NSScreen.main
    }
}
