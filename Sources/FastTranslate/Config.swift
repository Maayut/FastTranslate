import Foundation
import Carbon.HIToolbox

/// 应用配置（基于 UserDefaults，设置界面与运行时共用）
enum Config {
    private static let d = UserDefaults.standard

    // 翻译引擎
    static var engine: String {
        get { d.string(forKey: "engine") ?? "google" }
        set { d.set(newValue, forKey: "engine") }
    }

    static var deeplApiKey: String {
        get { d.string(forKey: "deeplApiKey") ?? "" }
        set { d.set(newValue, forKey: "deeplApiKey") }
    }

    static var deeplFreePlan: Bool {
        get { d.object(forKey: "deeplFreePlan") as? Bool ?? true }
        set { d.set(newValue, forKey: "deeplFreePlan") }
    }

    static var deepSeekApiKey: String {
        get { d.string(forKey: "deepSeekApiKey") ?? "" }
        set { d.set(newValue, forKey: "deepSeekApiKey") }
    }

    static var deepSeekModel: String {
        get { d.string(forKey: "deepSeekModel") ?? "deepseek-v4-flash" }
        set { d.set(newValue, forKey: "deepSeekModel") }
    }

    /// 自定义 API Base（留空用默认 https://api.deepseek.com，可填第三方 OpenAI 兼容地址）
    static var deepSeekBaseURL: String {
        get { d.string(forKey: "deepSeekBaseURL") ?? "" }
        set { d.set(newValue, forKey: "deepSeekBaseURL") }
    }

    // 语言
    static var sourceLang: String {
        get { d.string(forKey: "sourceLang") ?? "auto" }
        set { d.set(newValue, forKey: "sourceLang") }
    }

    static var targetLang: String {
        get { d.string(forKey: "targetLang") ?? "zh" }
        set { d.set(newValue, forKey: "targetLang") }
    }

    // 快捷键（Carbon 修饰键掩码 + 虚拟键码）
    static var hotKeyCode: Int {
        get { d.object(forKey: "hotKeyCode") as? Int ?? 2 } // 2 = 'D'
        set { d.set(newValue, forKey: "hotKeyCode") }
    }

    static var hotKeyModifiers: Int {
        get { d.object(forKey: "hotKeyModifiers") as? Int ?? Int(optionKey) } // 默认 ⌥
        set { d.set(newValue, forKey: "hotKeyModifiers") }
    }

    // 通用
    static var launchAtLogin: Bool {
        get { d.object(forKey: "launchAtLogin") as? Bool ?? false }
        set { d.set(newValue, forKey: "launchAtLogin") }
    }
}
