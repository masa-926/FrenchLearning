// Features/Quiz/QuizViewModel.swift
import Foundation
import SwiftUI

final class QuizViewModel: ObservableObject {
    // 出題元プール（QuizView からシャッフル再利用するので公開）
    @Published var allWords: [VocabWord]

    // 出題状態
    @Published private(set) var questions: [QuizQuestion] = []
    @Published private(set) var idx: Int = 0
    @Published var selected: String? = nil
    @Published private(set) var score: Int = 0
    @Published private(set) var finished: Bool = false

    // 結果から弱点復習用に使う（TodayPlan の relearnIDs に渡す）
    @Published var wrongWordIDs: [String] = []

    // どのパックから出題していたか（弱点復習で WordTrainer に戻すときに使う）
    let scopePackFilename: String?

    var totalQuestions: Int { questions.count }
    var current: QuizQuestion? {
        guard idx >= 0 && idx < questions.count else { return nil }
        return questions[idx]
    }

    init(
        sourceWords: [VocabWord],
        questionCount: Int = 10,
        scopePackFilename: String? = nil
    ) {
        self.allWords = sourceWords
        self.scopePackFilename = scopePackFilename
        generate(questionCount: questionCount)
    }

    /// 出題生成（4択）
    func generate(questionCount: Int) {
        finished = false
        score = 0
        idx = 0
        selected = nil
        wrongWordIDs = []

        guard allWords.count >= 4 else {
            questions = []
            return
        }

        let pool = allWords.shuffled()
        let take = min(questionCount, pool.count)

        var qs: [QuizQuestion] = []
        for i in 0..<take {
            let correct = pool[i]

            // ダミー3つ（重複・正解除外）
            var distractors = Array(pool.filter { $0.id != correct.id }.shuffled().prefix(3))
            if distractors.count < 3 {
                let rest = allWords.filter { w in
                    w.id != correct.id && !distractors.contains(where: { $0.id == w.id })
                }.shuffled()
                distractors.append(contentsOf: rest.prefix(3 - distractors.count))
            }

            qs.append(QuizQuestion(from: correct, options: distractors))
        }
        questions = qs
    }

    func select(option: String) { select(choice: option) }

    // 内部実装
    private func select(choice: String) {
        guard let q = current, selected == nil else { return }
        selected = choice

        let isCorrect = (choice == q.correctTermFr)

        // スコア
        if isCorrect { score += 1 }
        else if !wrongWordIDs.contains(q.correctID) { wrongWordIDs.append(q.correctID) }

        // SRS 反映（存在する語が allWords に入っていれば更新）
        if let w = allWords.first(where: { $0.id == q.correctID }) {
            SRSStore.shared.update(w, result: isCorrect ? .ok : .ng)
        }
    }

    func nextQuestion() {
        guard selected != nil else { return }
        selected = nil
        if idx + 1 < questions.count {
            idx += 1
        } else {
            finished = true
        }
    }

    /// 間違えた語だけで再出題（最低4語必要）
    func restartWeakMode() {
        let pool = allWords.filter { wrongWordIDs.contains($0.id) }
        guard pool.count >= 4 else {
            finished = true
            return
        }
        allWords = pool
        generate(questionCount: min(10, pool.count))
    }
}

