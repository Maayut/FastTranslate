import Foundation

/// 翻译引擎协议：新增引擎只需实现此协议并在 TranslatorFactory 注册
protocol Translator {
    var id: String { get }
    var displayName: String { get }

    /// from / to 使用统一语言代码（见 LangCode.all）
    func translate(_ text: String, from: String, to: String) async throws -> String
}

enum TranslateError: LocalizedError {
    case network(String)
    case parse(String)
    case missingKey(String)

    var errorDescription: String? {
        switch self {
        case .network(let s): return "网络错误：\(s)"
        case .parse(let s): return "解析错误：\(s)"
        case .missingKey(let s): return "缺少配置：\(s)"
        }
    }
}

extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
