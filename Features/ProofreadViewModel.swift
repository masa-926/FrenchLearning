//
//  Features:Proofread:ProofreadViewModel.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation
import SwiftUI

final class ProofreadViewModel: ObservableObject {
    @Published var input = ""
    @Published var result: ProofreadResult?
    @Published var isLoading = false
    @Published var error: String?

    private let client = OpenAIClient()
    @AppStorage("openai.mockEnabled") private var mockEnabled: Bool = false

    @MainActor
    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isLoading = true; error = nil
        defer { isLoading = false }

        if mockEnabled {
            self.result = Self.mock(for: text)
            return
        }

        do {
            self.result = try await client.proofread(text: text)
        } catch let e as OpenAIClient.APIError {
            switch e {
            case .insufficientQuota:
                self.error = "クレジット残高が不足しています（429）。Billingでクレジットを追加してください。今はモック結果を表示します。"
                self.result = Self.mock(for: text)
            default:
                self.error = e.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private static func mock(for text: String) -> ProofreadResult {
        ProofreadResult(
            corrected: "【修正例】" + text.replacingOccurrences(of: " ami ", with: " amis "),
            explanations: ["冠詞・数の一致を修正", "動詞の活用を訂正"]
        )
    }
}
