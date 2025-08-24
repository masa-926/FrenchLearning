//
//  QuizViewModel.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation
import SwiftUI

final class QuizViewModel: ObservableObject {
    @Published var allWords: [VocabWord] = []
    @Published var current: QuizQuestion?
    @Published var questionIndex: Int = 0
    @Published var totalQuestions: Int = 10
    @Published var score: Int = 0
    @Published var selected: String? = nil
    @Published var finished: Bool = false

    // ↓ 追加：弱点復習用
    @Published var wrongWordIDs: Set<String> = []
    private var wordByTerm: [String: VocabWord] = [:]

    init() { loadAndStart() }

    func loadAndStart() {
        if allWords.isEmpty {
            self.allWords = loadWordsFromBundle().shuffled()
        }
        // term→単語の辞書を構築（復習用）
        self.wordByTerm = Dictionary(uniqueKeysWithValues: allWords.map { ($0.term, $0) })

        guard allWords.count >= 4 else {
            current = nil
            finished = false
            return
        }
        score = 0
        questionIndex = 0
        finished = false
        wrongWordIDs.removeAll()         // ← 追加：新規開始でリセット
        nextQuestion()
    }

    func nextQuestion() {
        selected = nil
        guard questionIndex < totalQuestions else {
            finished = true
            return
        }
        let correct = allWords.randomElement()!
        let pool = allWords.filter { $0.term != correct.term }.shuffled()
        let distractors = Array(pool.prefix(3))
        current = QuizQuestion(from: correct, options: distractors)
        questionIndex += 1
    }

    func select(option: String) {
        guard selected == nil, let c = current else { return }
        selected = option
        if option == c.correctTermFr {
            score += 1
            Haptics.success()
        } else {
            // ↓ 追加：今回の“正解の単語”を弱点リストへ
            if let w = wordByTerm[c.correctTermFr] { wrongWordIDs.insert(w.id) }
            Haptics.error()
        }
    }

    // ↓ 追加：弱点だけで再スタート
    func restartWeakMode() {
        // IDs から単語配列を復元（4語未満ならそのまま allWords を使用）
        let weakWords = allWords.filter { wrongWordIDs.contains($0.id) }
        if weakWords.count >= 4 {
            allWords = weakWords.shuffled()
        }
        // 出題数は弱点数に合わせる（最大10）
        totalQuestions = min(10, allWords.count)
        score = 0
        questionIndex = 0
        finished = false
        selected = nil
        nextQuestion()
        // 辞書を再構築
        self.wordByTerm = Dictionary(uniqueKeysWithValues: allWords.map { ($0.term, $0) })
        // 次回のためにリセット
        wrongWordIDs.removeAll()
    }

    // --- 既存：Bundleローダ（あなたの前回版のままでOK） ---
    private func loadWordsFromBundle() -> [VocabWord] {
        if let url = Bundle.main.url(forResource: "wordset_fr_ja", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([VocabWord].self, from: data),
           !list.isEmpty {
            return list
        }
        let allPaths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        if let path = allPaths.first(where: { $0.lowercased().contains("wordset_fr_ja") }),
           let data = FileManager.default.contents(atPath: path),
           let list = try? JSONDecoder().decode([VocabWord].self, from: data),
           !list.isEmpty {
            return list
        }
        return []
    }
}
