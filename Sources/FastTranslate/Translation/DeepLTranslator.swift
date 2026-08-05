import Foundation

/// DeepL 翻译（官方 API，需在设置中填写 API Key；免费版/专业版可选）
struct DeepLTranslator: Translator {
    var id = "deepl"
    var displayName = "DeepL"
    var apiKey: String
    var freePlan: Bool = true

    func translate(_ text: String, from: String, to: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw TranslateError.missingKey("请在设置中填写 DeepL API Key")
        }

        let host = freePlan ? "api-free.deepl.com" : "api.deepl.com"
        let url = URL(string: "https://\(host)/v2/translate")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        var params: [String] = ["text=\(text.urlEncoded)"]
        if let target = LangCode.deepl(to) { params.append("target_lang=\(target)") }
        if let source = LangCode.deepl(from) { params.append("source_lang=\(source)") }
        request.httpBody = params.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslateError.network("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let translations = obj?["translations"] as? [[String: Any]],
           let first = translations.first,
           let text = first["text"] as? String {
            return text
        }
        throw TranslateError.parse("DeepL 响应异常")
    }
}
