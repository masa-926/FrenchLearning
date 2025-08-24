//
//  WordTrainerViewModel.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

// Features/Words/WordTrainerViewModel.swift
import SwiftUI
import Foundation

final class WordTrainerViewModel: ObservableObject {
    @Published var words: [VocabWord] = []
    @Published var index: Int = ProgressStore.shared.currentIndex
    @Published var showMeaning = false

    var current: VocabWord? {
        words.isEmpty ? nil : words[index % words.count]
    }

    init() { load() }

    func load() {
        // 1) ファイル存在チェック
        guard let url = Bundle.main.url(forResource: "wordset_fr_ja", withExtension: "json") else {
            let allJson = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
            print("⚠️ JSONが見つかりません。Bundle内のjson一覧:", allJson)
            fallback()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode([VocabWord].self, from: data)
            self.words = list.shuffled()
            print("✅ 読み込み成功。件数:", self.words.count)
        } catch {
            print("❌ デコード失敗:", error)
            fallback()
        }
    }

    private func fallback() {
        self.words = [
            VocabWord(id: "sample-1", term: "bonjour", meaningJa: "こんにちは", pos: "interj.", example: "Bonjour !"),
            VocabWord(id: "sample-2", term: "merci", meaningJa: "ありがとう", pos: "interj.", example: "Merci beaucoup.")
        ]
    }

    func reveal() { showMeaning = true }

    func next() {
        guard !words.isEmpty else { return }
        showMeaning = false
        index = (index + 1) % words.count
        ProgressStore.shared.currentIndex = index
    }
}

