// Models/VocabWord+LearningMeta.swift
import Foundation

extension VocabWord {
    /// 0=未学習, 1..=復習バケット
    var srsBucket: Int { SRSStore.shared.meta(for: self).bucket }
    /// 直近の復習で誤答したか
    var lastWrong: Bool { SRSStore.shared.meta(for: self).lastWrong }
    /// 最終復習日時
    var lastReviewedAt: Date? { SRSStore.shared.meta(for: self).lastReviewedAt }
    /// 失敗回数
    var lapses: Int { SRSStore.shared.meta(for: self).lapses }
}

