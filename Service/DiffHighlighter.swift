//
//  DiffHighlighter.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation
import SwiftUI

enum DiffHighlighter {
    // 公開API：元文と修正文から、装飾済みAttributedStringを返す
    static func highlight(original: String, corrected: String) -> (AttributedString, AttributedString) {
        let a = tokenize(original)
        let b = tokenize(corrected)
        let ops = diffOps(a, b) // a -> b の変換手順

        // 元文：equal と delete を表示（delete は赤取り消し）
        var orig = AttributedString()
        // 修正文：equal と insert を表示（insert は緑アンダーライン）
        var corr = AttributedString()

        let redStrike: AttributeContainer = {
            var c = AttributeContainer()
            c.foregroundColor = .red
            c.strikethroughStyle = .single
            return c
        }()

        let greenAdd: AttributeContainer = {
            var c = AttributeContainer()
            c.foregroundColor = .green
            c.underlineStyle = .single
            return c
        }()

        func appendWord(_ str: inout AttributedString, word: String, attr: AttributeContainer? = nil) {
            if !str.characters.isEmpty { str.append(AttributedString(" ")) }
            var a = AttributedString(word)
            if let attr { a.mergeAttributes(attr) }
            str.append(a)
        }

        for op in ops {
            switch op {
            case .equal(let w):
                appendWord(&orig, word: w)
                appendWord(&corr, word: w)
            case .delete(let w):
                appendWord(&orig, word: w, attr: redStrike)
            case .insert(let w):
                appendWord(&corr, word: w, attr: greenAdd)
            }
        }
        return (orig, corr)
    }

    // --- 内部実装：単語分割 & LCSベース差分 ---
    private static func tokenize(_ s: String) -> [String] {
        s.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    private enum Op { case equal(String), insert(String), delete(String) }

    private static func diffOps(_ a: [String], _ b: [String]) -> [Op] {
        let m = a.count, n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        // LCS 長さ表
        for i in stride(from: m - 1, through: 0, by: -1) {
            for j in stride(from: n - 1, through: 0, by: -1) {
                dp[i][j] = (a[i] == b[j]) ? dp[i+1][j+1] + 1 : max(dp[i+1][j], dp[i][j+1])
            }
        }
        // 復元して ops を作る
        var i = 0, j = 0
        var ops: [Op] = []
        while i < m && j < n {
            if a[i] == b[j] {
                ops.append(.equal(a[i])); i += 1; j += 1
            } else if dp[i+1][j] >= dp[i][j+1] {
                ops.append(.delete(a[i])); i += 1
            } else {
                ops.append(.insert(b[j])); j += 1
            }
        }
        while i < m { ops.append(.delete(a[i])); i += 1 }
        while j < n { ops.append(.insert(b[j])); j += 1 }
        return ops
    }
}
