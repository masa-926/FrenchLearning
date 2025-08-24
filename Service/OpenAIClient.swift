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
        case insufficientQuota
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "APIキーが未設定です（設定画面で保存してください）。"
            case .invalidStatus(let code, let body): return "サーバーエラー (\(code))：\(body)"
            case .emptyOutput: return "AIの出力が空でした。"
            case .decodeFailed(let s): return "JSONの解析に失敗しました：\(s)"
            case .insufficientQuota: return "クレジット残高が不足しています（insufficient_quota）。"
            }
        }
    }

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "openai.apiKey")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// フランス語の文章を校正 → {corrected, explanations[]} のJSONを返す
    func proofread(text: String) async throws -> ProofreadResult {
        guard let key = apiKey, !key.isEmpty else { throw APIError.missingAPIKey }

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 30

        // Responses API: input_text + text.format で Structured Outputs
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "input": [
                [
                    "role": "system",
                    "content": [[
                        "type": "input_text",
                        "text":
"""
あなたはフランス語の校正アシスタントです。ユーザーの文章の誤りを直し、
なぜ直したかを日本語で簡潔に説明します。
出力は必ず次のJSONスキーマに一致させてください。
"""
                    ]]
                ],
                [
                    "role": "user",
                    "content": [[
                        "type": "input_text",
                        "text":
"""
JSONスキーマ：
{ "corrected": string, "explanations": string[] }

校正対象テキスト：
\(text)
"""
                    ]]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "ProofreadResult",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "corrected": ["type": "string"],
                            "explanations": [
                                "type": "array",
                                "items": ["type": "string"]
                            ]
                        ],
                        "required": ["corrected", "explanations"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "max_output_tokens": 300
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.emptyOutput }
        guard (200...299).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 429 || bodyStr.contains("insufficient_quota") {
                throw APIError.insufficientQuota
            }
            throw APIError.invalidStatus(http.statusCode, bodyStr)
        }

        // 出力テキストを取り出し
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

        guard var payload = textJSON?.trimmingCharacters(in: .whitespacesAndNewlines),
              !payload.isEmpty else { throw APIError.emptyOutput }

        // ```json ... ``` フェンス除去（念のため）
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
