import Foundation

/// 学習結果（ユーザ操作から渡す）
public enum ReviewResult { case ok, hard, ng }

/// 単語ごとの SRS 記録
public struct SRSRecord: Codable, Equatable {
    public var bucket: Int              // 0=未学習, 1..=復習バケット
    public var ease: Double             // 学習容易度（初期2.5）
    public var lastReviewedAt: Date?    // 最終復習時刻
    public var lapses: Int              // 失敗回数
    public var lastWrong: Bool          // 直近で間違えたか

    public init(bucket: Int = 0, ease: Double = 2.5, lastReviewedAt: Date? = nil, lapses: Int = 0, lastWrong: Bool = false) {
        self.bucket = bucket
        self.ease = ease
        self.lastReviewedAt = lastReviewedAt
        self.lapses = lapses
        self.lastWrong = lastWrong
    }
}

/// 学習状態（統計やUI向けの抽象化）
public enum SRSPhase {
    case new           // まだ未学習
    case learning      // 学習入りたて（bucket==1 && 直近レビューなし 等）
    case review        // 通常の復習
    case relearning    // 直近で間違えた（復習やり直し）
    case leech         // 何度も間違える難物
}

/// 呼び出し側に返す情報セット（互換のため Optional 返しに対応）
public struct SRSStatus {
    public let state: SRSPhase
    public let record: SRSRecord
    public let isDue: Bool
}

/// SRS 永続ストア（UserDefaults に JSON で保存）
public final class SRSStore {
    public static let shared = SRSStore()

    private let ud = UserDefaults.standard
    private let keyRecords = "srs.records.v1"

    // メモリ上のキャッシュ
    private var records: [String: SRSRecord] = [:]

    private init() { loadFromDisk() }

    // MARK: - Public API（問い合わせ）

    /// 復習期限が来ている語を返す（bucket>0 かつ nextReviewAt <= now）
    public func dueWords<T>(from all: [T], now: Date = Date()) -> [T] {
        all.filter { isDue($0, now: now) }
    }

    /// 単語の記録を取得（なければデフォルトを返す）
    public func meta<T>(for word: T) -> SRSRecord {
        records[key(for: word)] ?? SRSRecord()
    }

    /// 期限切れか（ジェネリック：VocabWord 等）
    public func isDue<T>(_ word: T, now: Date = Date()) -> Bool {
        let rec = meta(for: word)
        return isDueRecord(rec, now: now)
    }

    /// 期限切れか（ID 直指定：String）
    public func isDue(id: String, now: Date = Date()) -> Bool {
        let rec = records["id:\(id)"] ?? SRSRecord()
        return isDueRecord(rec, now: now)
    }

    /// 学習状態の問い合わせ（ID 指定）
    /// 互換のため Optional で返し、呼び出し側の `?.state ?? .new` がそのまま動きます
    public func state(of id: String, now: Date = Date()) -> SRSStatus? {
        let rec = records["id:\(id)"] ?? SRSRecord()
        return SRSStatus(state: classify(rec), record: rec, isDue: isDueRecord(rec, now: now))
    }

    /// 学習状態の問い合わせ（ジェネリック：VocabWord 等）
    public func state<T>(of word: T, now: Date = Date()) -> SRSStatus? {
        let rec = meta(for: word)
        return SRSStatus(state: classify(rec), record: rec, isDue: isDueRecord(rec, now: now))
    }

    // MARK: - Public API（更新）

    /// 学習結果を反映して SRS を更新（単語オブジェクト版）
    public func update<T>(_ word: T, result: ReviewResult, now: Date = Date()) {
        let k = key(for: word)
        var rec = records[k] ?? SRSRecord()
        apply(&rec, result: result, now: now)
        records[k] = rec
        saveToDisk()
        notifyUpdated()
    }

    /// 学習結果を反映して SRS を更新（ID直指定版：String）
    public func mark(id: String, correct: Bool, now: Date = Date()) {
        updateByKey("id:\(id)", result: correct ? .ok : .ng, now: now)
    }

    /// 学習結果を反映して SRS を更新（ID直指定版：UUID）
    public func mark(uuid: UUID, correct: Bool, now: Date = Date()) {
        updateByKey("id:\(uuid.uuidString)", result: correct ? .ok : .ng, now: now)
    }

    /// 手動で記録を上書き（管理画面向け）
    public func setMeta<T>(_ word: T, _ rec: SRSRecord) {
        records[key(for: word)] = rec
        saveToDisk()
        notifyUpdated()
    }

    /// 全レコード（デバッグ・バックアップ用）
    public func dumpAll() -> [String: SRSRecord] { records }

    // MARK: - 内部：状態判定・間隔

    private func isDueRecord(_ rec: SRSRecord, now: Date) -> Bool {
        guard rec.bucket > 0 else { return false }
        guard let last = rec.lastReviewedAt else { return true } // 記録なしは即 due
        let days = intervalDays(for: rec)
        let next = last.addingTimeInterval(days * 86_400)
        return now >= next
    }

    /// Leitner 方式ベースの間隔（日）
    private func intervalDays(for rec: SRSRecord) -> Double {
        let base: [Int: Double] = [
            1: 0.5,  // 12h
            2: 1,    // 1d
            3: 3,    // 3d
            4: 7,    // 1w
            5: 14,   // 2w
            6: 30,   // 1m
            7: 60,   // 2m
            8: 120   // 4m
        ]
        let b = max(1, min(rec.bucket, 8))
        let baseDays = base[b] ?? 120
        // ease=2.5 を1.0倍基準に、1.3〜3.0 で ±30% 調整
        let factor = max(0.7, min(rec.ease / 2.5, 1.3))
        return baseDays * factor
    }

    private func classify(_ rec: SRSRecord) -> SRSPhase {
        if rec.bucket <= 0 { return .new }
        if rec.lapses >= 4 { return .leech }           // 閾値は運用で調整可
        if rec.lastWrong { return .relearning }
        if rec.bucket == 1 && rec.lastReviewedAt == nil { return .learning }
        return .review
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = ud.data(forKey: keyRecords) else { return }
        do {
            records = try JSONDecoder().decode([String: SRSRecord].self, from: data)
        } catch {
            records = [:] // 壊れていたら初期化
        }
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(records)
            ud.set(data, forKey: keyRecords)
        } catch {
            // 保存失敗は黙殺（頻発しない前提）
        }
    }

    // MARK: - Keying

    /// VocabWord など任意の型から、できるだけ安定したキーを作る
    private func key<T>(for word: T) -> String {
        let m = Mirror(reflecting: word)
        // 1) id を最優先（UUID / String / Int）
        for child in m.children where child.label == "id" {
            if let uuid = child.value as? UUID { return "id:\(uuid.uuidString)" }
            if let s    = child.value as? String, !s.isEmpty { return "id:\(s)" }
            if let n    = child.value as? Int { return "id:\(n)" }
        }
        // 2) lemma / surface
        for child in m.children {
            if child.label == "lemma", let s = child.value as? String, !s.isEmpty { return "lem:\(s)" }
            if child.label == "surface", let s = child.value as? String, !s.isEmpty { return "surf:\(s)" }
        }
        // 3) 最後の手段：型名+文字列表現
        return "desc:\(String(describing: type(of: word)))::\(String(describing: word))"
    }

    // MARK: - Update Core

    private func apply(_ rec: inout SRSRecord, result: ReviewResult, now: Date) {
        switch result {
        case .ok:
            rec.bucket = min(rec.bucket + 1, 8)
            rec.ease   = min(rec.ease + 0.05, 3.0)
            rec.lastWrong = false
        case .hard:
            rec.bucket = max(rec.bucket, 1)
            rec.ease   = max(rec.ease - 0.05, 1.3)
            rec.lastWrong = false
        case .ng:
            rec.bucket = 1
            rec.ease   = max(rec.ease - 0.2, 1.3)
            rec.lapses += 1
            rec.lastWrong = true
        }
        rec.lastReviewedAt = now
    }

    private func updateByKey(_ k: String, result: ReviewResult, now: Date) {
        var rec = records[k] ?? SRSRecord()
        apply(&rec, result: result, now: now)
        records[k] = rec
        saveToDisk()
        notifyUpdated()
    }

    // MARK: - Notification

    private func notifyUpdated() {
        NotificationCenter.default.post(name: .srsDidUpdate, object: nil)
    }
}

public extension Notification.Name {
    static let srsDidUpdate = Notification.Name("srsDidUpdate")
}

