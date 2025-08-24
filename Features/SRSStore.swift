//
//  SRSStore.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation

struct SRSState: Codable {
    var level: Int      // 0...4
    var due: Date       // 次の復習時刻
}

final class SRSStore {
    static let shared = SRSStore()
    private let defaults = UserDefaults.standard
    private let key = "srs.states" // [id: SRSState] をJSON保存
    private var states: [String: SRSState] = [:]

    private init() { load() }

    private func load() {
        if let data = defaults.data(forKey: key),
           let map = try? JSONDecoder().decode([String:SRSState].self, from: data) {
            states = map
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(states) {
            defaults.set(data, forKey: key)
        }
    }

    // テストしやすい高速モードか？（Settings のトグルで変更）
    private var fast: Bool {
        defaults.bool(forKey: "srs.fast") // default false -> days, true -> minutes
    }

    // レベル別の間隔（fast=true は分単位、false は日単位）
    private var intervals: [TimeInterval] {
        if fast {
            // 分: 0分, 1分, 5分, 15分, 60分
            return [0, 60, 5*60, 15*60, 60*60]
        } else {
            // 日: 0日, 1日, 3日, 7日, 14日
            return [0, 1*86400, 3*86400, 7*86400, 14*86400]
        }
    }

    func state(for id: String) -> SRSState {
        if let s = states[id] { return s }
        // 新規：すぐ復習対象にする（due = now, level=0）
        let s = SRSState(level: 0, due: Date())
        states[id] = s; save()
        return s
    }

    func isDue(_ id: String, now: Date = Date()) -> Bool {
        state(for: id).due <= now
    }

    func mark(id: String, correct: Bool, now: Date = Date()) {
        var s = state(for: id)
        if correct {
            s.level = min(s.level + 1, 4)
        } else {
            s.level = max(s.level - 1, 0)
        }
        s.due = now.addingTimeInterval(intervals[s.level])
        states[id] = s
        save()
    }

    func dueWords(from words: [VocabWord], now: Date = Date()) -> [VocabWord] {
        words.filter { isDue($0.id, now: now) }
    }
}

