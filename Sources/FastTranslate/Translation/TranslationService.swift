import Foundation

/// 翻译服务入口：读取配置 → 选引擎 → 翻译
enum TranslationService {
    static func translate(_ text: String) async throws -> String {
        let translator = TranslatorFactory.makeTranslator()
        return try await translator.translate(text,
                                              from: Config.sourceLang,
                                              to: Config.targetLang)
    }
}
