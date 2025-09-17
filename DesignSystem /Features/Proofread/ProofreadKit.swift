// Features/Proofread/ProofreadKit.swift
import SwiftUI
import Foundation

// ===== 共有モデル =====
struct ProofreadResult: Codable, Equatable {
    let corrected: String
    let explanations: [String]
}

// ===== オフラインバナー =====
struct OfflineBanner: View {
    let isOnline: Bool
    var body: some View {
        if !isOnline {
            Text("オフラインです。ネットワークに接続してください。")
                .font(.footnote)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.9))
                .foregroundStyle(.white)
        }
    }
}

// ===== ViewModel =====
@MainActor
final class ProofreadViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var isLoading: Bool = false
    @Published var result: ProofreadResult? = nil
    @Published var error: String? = nil

    private let client = OpenAIClient()

    func send(preferMock: Bool) async {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.error = "入力が空です。文章を入力してください。"
            self.result = nil
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            if preferMock {
                try await Task.sleep(nanoseconds: 300_000_000)
                let corrected = input
                    .replacingOccurrences(of: "je suis allé", with: "je suis allé(e)")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                self.result = ProofreadResult(
                    corrected: corrected.isEmpty ? "（入力が空です）" : corrected,
                    explanations: ["語尾の一致を確認しました", "不要な空白を削除しました"]
                )
                self.error = nil
            } else {
                let r = try await client.proofread(text: input)
                self.result = r
                self.error = nil
            }
        } catch {
            self.result = nil
            if let e = error as? LocalizedError, let desc = e.errorDescription {
                self.error = desc
            } else {
                self.error = "添削に失敗しました。時間をおいて再度お試しください。"
            }
        }
    }
}

