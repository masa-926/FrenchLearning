//
//  BookmarkStore.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/30.
//

import Foundation

final class BookmarkStore {
    static let shared = BookmarkStore()
    private let key = "bookmarks.wordIDs"
    private var set: Set<String> = []

    init() {
        if let d = UserDefaults.standard.array(forKey: key) as? [String] { set = Set(d) }
    }
    func toggle(id: String) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        UserDefaults.standard.set(Array(set), forKey: key)
    }
    func contains(_ id: String) -> Bool { set.contains(id) }
    func all() -> [String] { Array(set) }
}

