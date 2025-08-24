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

    private let client = OpenAIClient()

    @MainActor
    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            result = try await client.proofread(text: text) // ← ここに try が必要
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }
}
