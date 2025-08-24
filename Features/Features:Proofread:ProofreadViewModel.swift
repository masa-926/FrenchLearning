//
//  Features:Proofread:ProofreadViewModel.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation

final class ProofreadViewModel: ObservableObject {
    @Published var input = ""
    @Published var result: ProofreadResult?
    @Published var isLoading = false
    @Published var error: String?

    @MainActor
    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isLoading = true; error = nil
        defer { isLoading = false }

        // モック応答（0.5秒待って仮の結果を返す）
        try? await Task.sleep(nanoseconds: 500_000_000)
        self.result = ProofreadResult(
            corrected: "【修正例】" + text,
            explanations: ["冠詞の一致を修正", "動詞の活用を訂正"]
        )
    }
}
