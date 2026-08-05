import Foundation

/// Google 翻译（非官方接口，无需注册，开箱即用）
struct GoogleTranslator: Translator {
    var id = "google"
    var displayName = "Google 翻译"

    func translate(_ text: String, from: String, to: String) async throws -> String {
        var comps = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        comps.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: LangCode.google(from)),
            URLQueryItem(name: "tl", value: LangCode.google(to)),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text),
        ]
        guard let url = comps.url else { throw TranslateError.parse("URL 构造失败") }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslateError.network("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        // 响应结构：[[["译文","原文",...],...], "原语种", ...]
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [[Any]], !obj.isEmpty else {
            throw TranslateError.parse("响应格式异常")
        }

        var result = ""
        if let segments = obj.first as? [[Any]] {
            for segment in segments {
                if let s = segment.first as? String { result += s }
            }
        }
        guard !result.isEmpty else { throw TranslateError.parse("无翻译结果") }
        return result
    }
}
