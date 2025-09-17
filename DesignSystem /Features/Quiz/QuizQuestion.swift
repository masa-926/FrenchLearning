import Foundation

struct QuizQuestion: Identifiable, Equatable {
    let id: String                  // = 正解語の id
    let promptJa: String            // 日本語の出題文
    let correctTermFr: String       // 正解（フランス語）
    let correctID: String           // 正解語の id（冗長だけど可読性のため）
    let optionsFr: [String]         // 4択（フランス語）

    init(from correct: VocabWord, options: [VocabWord]) {
        self.id = correct.id
        self.correctID = correct.id
        self.correctTermFr = correct.term
        self.promptJa = (correct.meaningJa ?? correct.term)

        // options は「誤答候補」。ここに正解を足してシャッフル
        var opts = options.map { $0.term }
        opts.append(correct.term)
        // 重複除去してからシャッフル（稀に同語形が混ざるのを防止）
        let dedup = Array(Set(opts))
        if dedup.count >= 4 {
            self.optionsFr = Array(dedup.shuffled().prefix(4))
        } else {
            // 万一3未満になっても 4 件に満たすフォールバック
            var filled = dedup
            while filled.count < 4 { filled.append(correct.term) }
            self.optionsFr = filled.shuffled()
        }
    }
}

