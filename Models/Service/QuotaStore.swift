// Service/QuotaStore.swift
import Foundation

public final class QuotaStore {
    public static let shared = QuotaStore()

    private let defaults = UserDefaults.standard
    private let keyDate  = "quota.lastYMD"
    private let keyCount = "quota.count"

    private init() {}

    private func todayString() -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale   = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private func rolloverIfNeeded() {
        let today = todayString()
        let last = defaults.string(forKey: keyDate)
        if last != today {
            defaults.set(today, forKey: keyDate)
            defaults.set(0,     forKey: keyCount)
        }
    }

    public var countToday: Int {
        rolloverIfNeeded()
        return defaults.integer(forKey: keyCount)
    }

    @discardableResult
    public func increment() -> Int {
        rolloverIfNeeded()
        let c = defaults.integer(forKey: keyCount) + 1
        defaults.set(c, forKey: keyCount)
        return c
    }

    public func remaining(limit: Int) -> Int {
        return max(limit - countToday, 0)
    }

    public func resetToday() {
        defaults.set(todayString(), forKey: keyDate)
        defaults.set(0,             forKey: keyCount)
    }
}

