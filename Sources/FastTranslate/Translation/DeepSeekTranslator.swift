import Foundation

/// DeepSeek 翻译（OpenAI 兼容接口，中文翻译质量好、成本低，需 API Key）
/// 模型可在设置中选择（deepseek-chat / deepseek-reasoner / 自定义）
struct DeepSeekTranslator: Translator {
    var id = "deepseek"
    var displayName = "DeepSeek"
    var apiKey: String
    var model: String
    var baseURL: String

    func translate(_ text: String, from: String, to: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw TranslateError.missingKey("请在设置中填写 DeepSeek API Key")
        }

        // 模型/地址留空时用默认值
        let model = model.isEmpty ? "deepseek-v4-flash" : model
        let base = baseURL.isEmpty ? "https://api.deepseek.com" : baseURL
        guard let url = URL(string: base + "/chat/completions") else {
            throw TranslateError.parse("API Base 地址无效")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let targetName = LangCode.displayName(to)
        let system = "你是一名专业翻译。把用户提供的文本翻译成\(targetName)。只输出译文，不要任何解释或附加内容。"
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": text],
            ],
            "temperature": 0.3,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslateError.network("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = obj?["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw TranslateError.parse("DeepSeek 响应异常")
    }
}
