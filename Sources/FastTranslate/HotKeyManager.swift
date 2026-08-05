import AppKit
import Carbon.HIToolbox

/// 全局快捷键管理（基于 Carbon RegisterEventHotKey，无需「输入监控」权限）
final class HotKeyManager {
    static let shared = HotKeyManager()

    /// 快捷键按下时的回调
    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private let hotKeySignature: OSType = 0x4654_4B48 // "FTKH"

    private init() {}

    /// 注册（或重新注册）全局快捷键
    func register(keyCode: Int, modifiers: Int) {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            HotKeyManager.shared.onHotKey?()
            return noErr
        }, 1, &eventType, nil, nil)

        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: 1)
        RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    // MARK: - 显示

    /// 当前快捷键的人类可读显示，如 "⌥D"
    var currentDisplay: String {
        let code = Config.hotKeyCode
        let mods = Config.hotKeyModifiers
        var parts: [String] = []
        if mods & Int(cmdKey) != 0 { parts.append("⌘") }
        if mods & Int(optionKey) != 0 { parts.append("⌥") }
        if mods & Int(controlKey) != 0 { parts.append("⌃") }
        if mods & Int(shiftKey) != 0 { parts.append("⇧") }
        parts.append(keyName(code))
        return parts.joined()
    }

    private func keyName(_ code: Int) -> String {
        let names: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "B", 11: "Q", 12: "W", 13: "E", 14: "R", 15: "Y",
            16: "T", 17: "1", 18: "2", 19: "3", 20: "4", 21: "6", 22: "5", 23: "=",
            24: "9", 25: "7", 26: "-", 27: "8", 28: "0", 29: "]", 30: "O", 31: "U",
            32: "[", 33: "I", 34: "P", 35: "L", 36: "J", 37: "'", 38: "K", 39: ";",
            40: "\\", 41: ",", 42: "/", 43: "N", 44: "M", 45: ".", 46: "Tab", 47: "Space",
            48: "`", 49: "Backspace", 50: "Return", 51: "Esc", 53: "Esc",
        ]
        return names[code] ?? "Key\(code)"
    }
}
