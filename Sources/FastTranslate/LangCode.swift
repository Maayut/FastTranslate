import Foundation

/// 语言代码：设置界面使用的统一代码 → 各翻译引擎专用代码
enum LangCode {
    static let all: [(code: String, display: String)] = [
        ("auto", "自动检测"),
        ("zh", "中文"),
        ("en", "English"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("es", "Español"),
        ("ru", "Русский"),
    ]

    /// Google 翻译的语种代码
    static func google(_ code: String) -> String {
        switch code {
        case "zh": return "zh-CN"
        case "auto": return "auto"
        default: return code
        }
    }

    /// DeepL 的语种代码（返回 nil 表示省略该字段 → 自动检测）
    static func deepl(_ code: String) -> String? {
        switch code {
        case "auto": return nil
        default: return code.uppercased()
        }
    }

    /// 语言中文显示名（用于 LLM 类引擎的提示词）
    static func displayName(_ code: String) -> String {
        all.first { $0.code == code }?.display ?? code
    }
}
