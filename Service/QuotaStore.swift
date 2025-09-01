//
//  git add . git commit -m "feat(proofread)- add word-level diff highlighting (insert:delete)" git push .swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation

final class DailyQuotaStore {
    static let shared = DailyQuotaStore()
    private let defaults = UserDefaults.standard
    private let keyDate = "quota.lastYMD"
    private let keyCount = "quota.count"

    private func todayString() -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private func rolloverIfNeeded() {
        let today = todayString()
        let last = defaults.string(forKey: keyDate)
        if last != today {
            defaults.set(today, forKey: keyDate)
            defaults.set(0, forKey: keyCount)
        }
    }

    var countToday: Int {
        rolloverIfNeeded()
        return defaults.integer(forKey: keyCount)
    }

    @discardableResult
    func increment() -> Int {
        rolloverIfNeeded()
        let c = defaults.integer(forKey: keyCount) + 1
        defaults.set(c, forKey: keyCount)
        return c
    }

    func remaining(limit: Int) -> Int {
        max(limit - countToday, 0)
    }

    func resetToday() {
        defaults.set(todayString(), forKey: keyDate)
        defaults.set(0, forKey: keyCount)
    }
}
