import AppKit
import ApplicationServices

/// 选中的文本及其屏幕位置
struct SelectionInfo {
    let text: String
    /// 选区在屏幕上的位置（AX 全局坐标系：左上角原点）
    let bounds: CGRect?
}

/// 读取当前选中的文本。
/// 主路径：辅助功能 API（AXSelectedText，不碰剪贴板）
/// 兜底：模拟 Cmd+C 读取剪贴板（兼容部分不支持辅助功能的应用）
enum SelectionReader {
    static func readSelection() -> SelectionInfo? {
        if let info = readViaAccessibility(), !info.text.isEmpty {
            return info
        }
        if let text = readViaClipboard(), !text.isEmpty {
            return SelectionInfo(text: text, bounds: nil)
        }
        return nil
    }

    // MARK: - 辅助功能 API

    private static func readViaAccessibility() -> SelectionInfo? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide,
                                            kAXFocusedUIElementAttribute as CFString,
                                            &focusedValue) == .success,
              let focusedValue else { return nil }
        let element = focusedValue as! AXUIElement

        var selectedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                            kAXSelectedTextAttribute as CFString,
                                            &selectedValue) == .success,
              let text = selectedValue as? String else { return nil }

        // 尝试获取选区位置（用于弹窗定位；失败不影响翻译）
        var bounds: CGRect?
        var rangeValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element,
                                         kAXSelectedTextRangeAttribute as CFString,
                                         &rangeValue) == .success,
           let rangeValue {
            var boundsValue: CFTypeRef?
            if AXUIElementCopyParameterizedAttributeValue(element,
                                                          kAXBoundsForRangeParameterizedAttribute as CFString,
                                                          rangeValue,
                                                          &boundsValue) == .success,
               let boundsValue {
                let axValue = boundsValue as! AXValue
                if AXValueGetType(axValue) == .cgRect {
                    var rect = CGRect.zero
                    AXValueGetValue(axValue, .cgRect, &rect)
                    bounds = rect
                }
            }
        }

        return SelectionInfo(text: text, bounds: bounds)
    }

    // MARK: - 剪贴板兜底

    private static func readViaClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        let savedData = pasteboard.data(forType: .string)
        let savedString = pasteboard.string(forType: .string)

        // 模拟 Cmd+C（需要辅助功能权限）
        let source = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true) // 8 = 'C'
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)

        Thread.sleep(forTimeInterval: 0.15)
        let text = pasteboard.string(forType: .string)

        // 恢复剪贴板
        pasteboard.clearContents()
        if let data = savedData {
            pasteboard.setData(data, forType: .string)
        } else if let savedString {
            pasteboard.setString(savedString, forType: .string)
        }

        return text
    }
}
