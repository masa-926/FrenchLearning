//
//  QuizQuestion.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation

struct QuizQuestion: Identifiable {
    let id = UUID().uuidString
    let promptJa: String         // 日本語の意味（問題文）
    let correctTermFr: String    // 正解のフランス語
    let optionsFr: [String]      // 4択（フランス語）

    init(from word: VocabWord, options: [VocabWord]) {
        self.promptJa = word.meaningJa
        self.correctTermFr = word.term
        self.optionsFr = ([word] + options).map { $0.term }.shuffled()
    }
}
