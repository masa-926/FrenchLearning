//
//  OpenAIClient.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation

final class OpenAIClient {
    enum APIError: Error, LocalizedError {
        case missingAPIKey
        case invalidStatus(Int, String)
        case emptyOutput
        case decodeFailed(String)
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "APIキーが未設定です（設定画面で保存してください）。"
            case .invalidStatus(let code, let body): return "サーバーエラー (\(code))：\(body)"
            case .emptyOutput: return "AIの出力が空でした。"
            case .decodeFailed(let s): return "JSONの解析に失敗しました：\(s)"
            }
        }
    }

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "openai.apiKey")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func proofread(text: String) async throws -> ProofreadResult {
        guard let key = apiKey, !key.isEmpty else { throw APIError.missingAPIKey }

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "input": [
                ["role": "system", "content": [
                    ["type": "text", "text":
                        "あなたはフランス語の校正アシスタント。出力は必ず {\"corrected\": string, \"explanations\": string[]} のJSONだけ。"]
                ]],
                ["role": "user", "content": [
                    ["type": "text", "text":
                        """
                        JSONスキーマ：
                        { "corrected": string, "explanations": string[] }

                        校正対象テキスト：
                        \(text)
                        """
                    ]
                ]]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "Proofread",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "corrected": ["type": "string"],
                            "explanations": ["type": "array", "items": ["type": "string"]]
                        ],
                        "required": ["corrected", "explanations"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "max_output_tokens": 800
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.emptyOutput }
        guard (200...299).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw APIError.invalidStatus(http.statusCode, bodyStr)
        }

        // JSON文字列の取り出し
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        var textJSON: String?
        if let t = root?["output_text"] as? String {
            textJSON = t
        } else if
            let output = root?["output"] as? [[String: Any]],
            let first = output.first,
            let content = first["content"] as? [[String: Any]] {
            textJSON = content.compactMap { $0["text"] as? String }.joined()
        }
        guard var payload = textJSON?.trimmingCharacters(in: .whitespacesAndNewlines), !payload.isEmpty
        else { throw APIError.emptyOutput }

        // ```json フェンス除去
        if let s = payload.range(of: "```"),
           let e = payload.range(of: "```", range: s.upperBound..<payload.endIndex) {
            payload = String(payload[s.upperBound..<e.lowerBound])
        }

        guard let payloadData = payload.data(using: .utf8)
        else { throw APIError.decodeFailed("UTF-8変換に失敗") }

        do {
            return try JSONDecoder().decode(ProofreadResult.self, from: payloadData)
        } catch {
            throw APIError.decodeFailed("payload=\(payload)")
        }
    }
}
