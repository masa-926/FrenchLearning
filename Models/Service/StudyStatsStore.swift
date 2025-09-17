// Service/StudyStatsstore.swift
import Foundation
import Combine

/// 1日の学習統計（当日分のみ扱うシンプル実装）
public final class StudyStatsStore: ObservableObject {
    public static let shared = StudyStatsStore()

    @Published public private(set) var todayNew: Int = 0
    @Published public private(set) var todayReviewOK: Int = 0
    @Published public private(set) var todayReviewNG: Int = 0
    @Published public private(set) var todayRelearn: Int = 0

    private let ud = UserDefaults.standard
    private let keyDate = "stats.date"
    private let keyNew  = "stats.new"
    private let keyROK  = "stats.rev.ok"
    private let keyRNG  = "stats.rev.ng"
    private let keyRLN  = "stats.relearn"

    private init() {
        rolloverIfNeeded()
        load()
    }

    // MARK: - Public API
    public func bumpNew() {
        rolloverIfNeeded()
        todayNew += 1
        save(); notify()
    }

    public func bumpReview(correct: Bool) {
        rolloverIfNeeded()
        if correct { todayReviewOK += 1 } else { todayReviewNG += 1 }
        save(); notify()
    }

    public func bumpRelearn() {
        rolloverIfNeeded()
        todayRelearn += 1
        save(); notify()
    }

    public func resetToday() {
        let d = Self.todayString()
        ud.set(d, forKey: keyDate)
        ud.set(0, forKey: keyNew)
        ud.set(0, forKey: keyROK)
        ud.set(0, forKey: keyRNG)
        ud.set(0, forKey: keyRLN)
        load(); notify()
    }

    // MARK: - Private
    private func load() {
        todayNew      = ud.integer(forKey: keyNew)
        todayReviewOK = ud.integer(forKey: keyROK)
        todayReviewNG = ud.integer(forKey: keyRNG)
        todayRelearn  = ud.integer(forKey: keyRLN)
    }

    private func save() {
        ud.set(todayNew,      forKey: keyNew)
        ud.set(todayReviewOK, forKey: keyROK)
        ud.set(todayReviewNG, forKey: keyRNG)
        ud.set(todayRelearn,  forKey: keyRLN)
    }

    private func rolloverIfNeeded() {
        let today = Self.todayString()
        let last  = ud.string(forKey: keyDate)
        if last != today {
            ud.set(today, forKey: keyDate)
            ud.set(0, forKey: keyNew)
            ud.set(0, forKey: keyROK)
            ud.set(0, forKey: keyRNG)
            ud.set(0, forKey: keyRLN)
        }
    }

    private static func todayString() -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private func notify() {
        NotificationCenter.default.post(name: .statsDidUpdate, object: nil)
    }
}

// 既存コードが古いクラス名を参照していてもビルドが通るように
public typealias StudyStatsstore = StudyStatsStore

public extension Notification.Name {
    static let statsDidUpdate = Notification.Name("statsDidUpdate")
}

