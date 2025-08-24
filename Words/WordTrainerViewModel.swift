import Foundation
import SwiftUI

final class WordTrainerViewModel: ObservableObject {
    // 学習データ
    @Published var words: [VocabWord] = []
    @Published var index: Int = 0
    @Published var showMeaning: Bool = false

    // 現在の単語
    var current: VocabWord? {
        guard !words.isEmpty, index >= 0, index < words.count else { return nil }
        return words[index]
    }

    // SRS
    private let srs = SRSStore.shared
    @AppStorage("srs.enabled") private var srsEnabled: Bool = true

    init() {
        load()
        // 保存された進捗から再開（範囲安全化）
        let saved = ProgressStore.shared.currentIndex
        if !words.isEmpty { index = min(max(0, saved), words.count - 1) }
    }

    // JSON読み込み（部分一致フォールバック付き）
    private func load() {
        if let url = Bundle.main.url(forResource: "wordset_fr_ja", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([VocabWord].self, from: data),
           !list.isEmpty {
            self.words = list
            return
        }
        let all = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        if let path = all.first(where: { $0.lowercased().contains("wordset_fr_ja") }),
           let data = FileManager.default.contents(atPath: path),
           let list = try? JSONDecoder().decode([VocabWord].self, from: data),
           !list.isEmpty {
            self.words = list
            return
        }
        // 最終フォールバック（最低限の3語）
        self.words = [
            VocabWord(id: "f1", term: "bonjour", meaningJa: "こんにちは", pos: "interj.", example: "Bonjour, ça va ?"),
            VocabWord(id: "f2", term: "merci",   meaningJa: "ありがとう", pos: "interj.", example: "Merci beaucoup !"),
            VocabWord(id: "f3", term: "pomme",   meaningJa: "りんご", pos: "n.", example: "Je mange une pomme.")
        ]
    }

    // MARK: - 既存操作
    @MainActor func reveal() { showMeaning = true }

    @MainActor func next() {
        guard !words.isEmpty else { return }
        showMeaning = false
        index = (index + 1) % words.count
        ProgressStore.shared.currentIndex = index
    }

    // MARK: - SRS操作
    /// 「覚えた/まだ」のボタンから呼ぶ
    @MainActor
    func review(correct: Bool) {
        guard let w = current else { return }
        srs.mark(id: w.id, correct: correct)
        loadNextDue()
    }

    /// SRSで“次に復習すべき単語”へ進む
    @MainActor
    func nextDue() { loadNextDue() }

    /// SRSで期限到来の単語から次を選ぶ
    @MainActor
    private func loadNextDue() {
        guard srsEnabled else { return } // SRS無効なら何もしない（next()を使う）
        let due = srs.dueWords(from: words)
        // 今と同じIDはスキップ
        if let next = due.first(where: { $0.id != current?.id }),
           let i = words.firstIndex(where: { $0.id == next.id }) {
            index = i
            showMeaning = false
            ProgressStore.shared.currentIndex = index
        }
    }

    /// 初回表示時に、SRSが有効なら復習対象に合わせて current を調整
    @MainActor
    func alignToSRSIfNeeded() {
        guard srsEnabled else { return }
        if current == nil || !(current.map { srs.isDue($0.id) } ?? false) {
            loadNextDue()
        }
    }
}

