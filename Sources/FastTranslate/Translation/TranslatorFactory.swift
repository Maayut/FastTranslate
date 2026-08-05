import Foundation

/// 根据配置创建翻译引擎
enum TranslatorFactory {
    struct EngineOption {
        let id: String
        let display: String
    }

    static let options: [EngineOption] = [
        .init(id: "google", display: "Google 翻译（无需配置）"),
        .init(id: "deepl", display: "DeepL（需 API Key）"),
        .init(id: "deepseek", display: "DeepSeek（需 API Key）"),
    ]

    static func makeTranslator() -> Translator {
        switch Config.engine {
        case "deepl":
            return DeepLTranslator(apiKey: Config.deeplApiKey, freePlan: Config.deeplFreePlan)
        case "deepseek":
            return DeepSeekTranslator(apiKey: Config.deepSeekApiKey,
                                      model: Config.deepSeekModel,
                                      baseURL: Config.deepSeekBaseURL)
        default:
            return GoogleTranslator()
        }
    }
}
