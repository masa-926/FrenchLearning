// Models/PlanBuilder.swift
import Foundation

public protocol ProgressReading {
    var wrongWordIDs: Set<String> { get }  // 間違えた語
    var dueReviewIDs: [String] { get }     // 期限が来た復習ID
}

public struct PlanBuilder {
    public init() {}

    /// loadedIDs: そのユニットに含まれる語ID（String）
    public func build(
        loadedIDs: [String],
        progress: ProgressReading,
        learning stepLearning: Int = 10,
        review stepReview: Int = 20,
        relearning stepRelearning: Int = 10
    ) -> TodayPlan {

        let relearn = Array(progress.wrongWordIDs.prefix(stepRelearning))

        // まだ学習していない語 = loadedIDs から (復習対象 + 再学習対象) を除外したものの先頭から
        let exclude = Set(progress.dueReviewIDs).union(relearn)
        let newPool = loadedIDs.filter { !exclude.contains($0) }
        let new = Array(newPool.prefix(stepLearning))

        let review = Array(progress.dueReviewIDs.prefix(stepReview))

        return TodayPlan(newIDs: new, reviewIDs: review, relearnIDs: Array(relearn))
    }
}

// 例: UnitProgressStore を ProgressReading に適合させる（実プロパティ名に合わせて調整）
/*
extension UnitProgressStore: ProgressReading {
    public var wrongWordIDs: Set<String> { self.wrongIDs }  // 実際のプロパティ名に合わせて
    public var dueReviewIDs: [String] { self.dueIDs }       // 実際のプロパティ名に合わせて
}
*/

// === Append to Models/PlanBuilder.swift ===

public enum PlanScope {
    case unit(filename: String)
    case all
}

public extension PlanBuilder {
    /// TodayStartView から使う高レベル構築API
    static func build(scope: PlanScope, goal: Int, fast: Bool) -> TodayPlan {
        // 目標値を new/review/relearn にざっくり配分
        let learn = max(0, goal / 3)
        let rev   = max(0, goal - learn)
        let rele  = max(0, min(10, goal / 4))

        switch scope {
        case .unit(let filename):
            let words = VocabLoader.shared.load(fileNamed: filename)
            return PlanBuilder.shared.buildPlan(
                for: filename,
                words: words,
                learning: learn,
                review: rev,
                relearning: rele
            )

        case .all:
            let words = VocabLoader.shared.loadAll()
            return PlanBuilder.shared.buildPlan(
                for: "ALL",
                words: words,
                learning: learn,
                review: rev,
                relearning: rele
            )
        }
    }
}
