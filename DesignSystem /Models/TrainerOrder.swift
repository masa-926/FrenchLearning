//
//  TrainerOrder.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/28.
//

import Foundation

enum TrainerOrder: String, CaseIterable, Codable {
    case pack     // JSON(ユニット)の順
    case shuffle  // シャッフル
    case weak     // 苦手順：復習期限が近い/到来している語を優先

    var title: String {
        switch self {
        case .pack:    return "パック順"
        case .shuffle: return "シャッフル"
        case .weak:    return "苦手順"
        }
    }
}
