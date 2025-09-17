//  UnitProgressStore.swift
//  FrenchLearning

import Foundation

struct UnitProgress: Codable {
    var lastIndex: Int
    var seenIDs: Set<String>
}

final class UnitProgressStore {
    static let shared = UnitProgressStore()

    private let key = "unit.progress.v2"          // 新しい保存キー
    private var map: [String: UnitProgress] = [:] // packFilename -> progress

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let loaded = try? JSONDecoder().decode([String: UnitProgress].self, from: data) {
            map = loaded
        }
    }

    // 読み出し（存在しなければデフォルト）
    func progress(for pack: String) -> UnitProgress {
        map[pack] ?? UnitProgress(lastIndex: 0, seenIDs: [])
    }

    // 既読マーク（冪等：同じIDは1回だけ数える）
    func markSeen(id: String, pack: String) {
        var p = progress(for: pack)
        let inserted = p.seenIDs.insert(id).inserted
        if inserted {
            map[pack] = p
            save()
        }
    }

    func seenCount(for pack: String) -> Int {
        progress(for: pack).seenIDs.count
    }

    func setLastIndex(_ idx: Int, for pack: String) {
        var p = progress(for: pack)
        p.lastIndex = idx
        map[pack] = p
        save()
    }

    func reset(for pack: String) {
        map[pack] = UnitProgress(lastIndex: 0, seenIDs: [])
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

