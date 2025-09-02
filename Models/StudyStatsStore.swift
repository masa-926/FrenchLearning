// Service/StudyStatsStore.swift
import Foundation
import SwiftUI

/// 学習統計（日次）
final class StudyStatsStore: ObservableObject {
    static let shared = StudyStatsStore()

    @Published private(set) var todayNew: Int = 0
    @Published private(set) var todayReviewOK: Int = 0
    @Published private(set) var todayReviewNG: Int = 0
    @Published private(set) var todayRelearn: Int = 0

    private let ud = UserDefaults.standard
    private let keyYMD   = "studyStats.ymd.v1"
    private let keyNew   = "studyStats.today.new.v1"
    private let keyROK   = "studyStats.today.reviewOK.v1"
    private let keyRNG   = "studyStats.today.reviewNG.v1"
    private let keyRL    = "studyStats.today.relearn.v1"

    private init() {
        rolloverIfNeeded(loadOnly: true)
    }

    // MARK: - Public API (ViewModel から呼ぶ)
    func bumpNew() {
        rolloverIfNeeded()
        todayNew += 1
        persist()
    }

    func bumpReview(correct: Bool) {
        rolloverIfNeeded()
        if correct { todayReviewOK += 1 } else { todayReviewNG += 1 }
        persist()
    }

    func bumpRelearn() {
        rolloverIfNeeded()
        todayRelearn += 1
        persist()
    }

    func resetToday() {
        setTodayCounts(new: 0, rOK: 0, rNG: 0, rl: 0)
    }

    // MARK: - Internal
    private func todayString() -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private func rolloverIfNeeded(loadOnly: Bool = false) {
        let ymd = todayString()
        let last = ud.string(forKey: keyYMD)
        if last != ymd {
            ud.set(ymd, forKey: keyYMD)
            if loadOnly {
                // 初回ロード：保存値があれば読む、なければ0
                todayNew       = ud.integer(forKey: keyNew)
                todayReviewOK  = ud.integer(forKey: keyROK)
                todayReviewNG  = ud.integer(forKey: keyRNG)
                todayRelearn   = ud.integer(forKey: keyRL)
                // ただし日付が違えばリセット
                if last != nil { setTodayCounts(new: 0, rOK: 0, rNG: 0, rl: 0) }
            } else {
                setTodayCounts(new: 0, rOK: 0, rNG: 0, rl: 0)
            }
        } else if loadOnly {
            // 同日読み込み
            todayNew       = ud.integer(forKey: keyNew)
            todayReviewOK  = ud.integer(forKey: keyROK)
            todayReviewNG  = ud.integer(forKey: keyRNG)
            todayRelearn   = ud.integer(forKey: keyRL)
        }
    }

    private func setTodayCounts(new: Int, rOK: Int, rNG: Int, rl: Int) {
        todayNew = new; todayReviewOK = rOK; todayReviewNG = rNG; todayRelearn = rl
        persist()
    }

    private func persist() {
        ud.set(todayNew,      forKey: keyNew)
        ud.set(todayReviewOK, forKey: keyROK)
        ud.set(todayReviewNG, forKey: keyRNG)
        ud.set(todayRelearn,  forKey: keyRL)
        NotificationCenter.default.post(name: .studyStatsDidUpdate, object: nil)
    }
}

public extension Notification.Name {
    static let studyStatsDidUpdate = Notification.Name("studyStatsDidUpdate")
}

