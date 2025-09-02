//
//  Log.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation
import os

enum Log {
    // 例: com.yourname.FrenchLearning
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.yourname.FrenchLearning"

    // 用途別のロガー
    static let app       = Logger(subsystem: subsystem, category: "app")
    static let words     = Logger(subsystem: subsystem, category: "words")
    static let proofread = Logger(subsystem: subsystem, category: "proofread")
    static let network   = Logger(subsystem: subsystem, category: "network")
    static let ui        = Logger(subsystem: subsystem, category: "ui")

    // パフォーマンス測定用サインポスト
    static let perf = OSSignposter(subsystem: subsystem, category: "perf")
}

