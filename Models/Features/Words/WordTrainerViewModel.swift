import SwiftUI
import Foundation

/// その日の配分カウンタ
private struct SessionQuota {
    var goal: Int
    var done: Int = 0
    var reviewQuota: Int
    var relearnQuota: Int
    var newQuota: Int

    mutating func bump(_ kind: Kind) {
        done += 1
        switch kind {
        case .review:  reviewQuota  = max(0, reviewQuota - 1)
        case .relearn: relearnQuota = max(0, relearnQuota - 1)
        case .new:     newQuota     = max(0, newQuota - 1)
        case .fallback: break
        }
    }

    func allows(_ kind: Kind) -> Bool {
        switch kind {
        case .review:  return reviewQuota  > 0
        case .relearn: return relearnQuota > 0
        case .new:     return newQuota     > 0
        case .fallback: return true
        }
    }

    enum Kind { case review, relearn, new, fallback }
}

/// クイズからの誤答をブリッジする軽量バッファ（別ファイルの MistakeBuffer から吸い上げ）
private struct MistakesQueue {
    private(set) var ids: [String] = []

    init(seed: [String]) { self.ids = seed }

    mutating func popNext(in words: [VocabWord], notSameAs currentID: String?) -> VocabWord? {
        guard !ids.isEmpty else { return nil }
        // 先頭から、現在カードと被らない & 現在プールに存在するものを探す
        for (i, id) in ids.enumerated() {
            if id == currentID { continue }
            if let w = words.first(where: { $0.id == id }) {
                ids.remove(at: i)
                return w
            }
        }
        return nil
    }

    mutating func pushBack(_ id: String) {
        // 同一 ID を詰め込みすぎないよう軽く制限
        if ids.filter({ $0 == id }).count < 2 {
            ids.append(id)
        }
    }
}

final class WordTrainerViewModel: ObservableObject {
    // ==== 外部依存 ====
    private let packFilename: String?
    private let up = UnitProgressStore.shared
    private let srs = SRSStore.shared

    // ==== 生配列（ユニット読込後の元データ） ====
    private var baseWords: [VocabWord] = []

    // ==== 表示用（並び替え後） ====
    @Published var words: [VocabWord] = []
    @Published var index: Int = 0
    @Published var showMeaning: Bool = false
    @Published var finishedNonSRS: Bool = false

    // 現在カード
    var current: VocabWord? {
        guard !words.isEmpty, index >= 0, index < words.count else { return nil }
        return words[index]
    }
    var packFile: String? { packFilename }

    // ==== 設定 ====
    @AppStorage("srs.enabled") private var srsEnabled: Bool = true
    @AppStorage("trainer.order") private var orderRaw: String = TrainerOrder.pack.rawValue

    // 今日の配分（ソフトキュー用）
    @AppStorage("session.goal") private var sessionGoal: Int = 20
    @AppStorage("session.share.review") private var shareReview: Int = 60
    @AppStorage("session.share.relearn") private var shareRelearn: Int = 20
    @AppStorage("session.share.new") private var shareNew: Int = 20
    @AppStorage("session.highFreqFirst") private var highFreqFirst: Bool = true

    // ソフトキューの状態
    private var quota: SessionQuota = .init(goal: 20, reviewQuota: 12, relearnQuota: 4, newQuota: 4)
    private var mistakes: MistakesQueue = .init(seed: MistakeBuffer.shared.drain())

    // 旧互換フィルタ（通常導線では不使用）
    @AppStorage("filter.cefr") private var cefrFilter: String = "All"
    @AppStorage("filter.highFreqOnly") private var highFreqOnly: Bool = false
    @AppStorage("filter.topicsCSV") private var topicsCSV: String = ""

    // MARK: - Init
    init(packFilename: String? = nil, initialPlan: TodayPlan? = nil) {
        self.packFilename = packFilename
        load()
        // 再開位置：ユニット優先、なければ旧全体進捗
        if let file = packFilename {
            let last = up.progress(for: file).lastIndex
            if !words.isEmpty { index = min(max(0, last), words.count - 1) }
        } else {
            let saved = ProgressStore.shared.currentIndex
            if !words.isEmpty { index = min(max(0, saved), words.count - 1) }
        }
        // initialPlan は受け口だけ保持（固定キューは使わない）
        _ = initialPlan
        rebuildQuota()
    }

    // 旧 API 互換
    convenience init() { self.init(packFilename: nil, initialPlan: nil) }

    // MARK: - Load
    private func load() {
        if let file = packFilename, !file.isEmpty {
            baseWords = VocabLoader.shared.load(fileNamed: file)
        } else {
            let all = VocabLoader.shared.loadAll()
            baseWords = applyFilters(to: all)
        }

        if baseWords.isEmpty {
            baseWords = [
                VocabWord(id: "f1", term: "bonjour", meaningJa: "こんにちは", pos: "interj.", example: "Bonjour, ça va ?"),
                VocabWord(id: "f2", term: "merci",   meaningJa: "ありがとう", pos: "interj.", example: "Merci beaucoup !"),
                VocabWord(id: "f3", term: "pomme",   meaningJa: "りんご", pos: "n.",        example: "Je mange une pomme.")
            ]
        }
        applyOrdering()
    }

    // MARK: - 並び替え（見た目用）
    private func applyOrdering() {
        let order = TrainerOrder(rawValue: orderRaw) ?? .pack
        switch order {
        case .pack:
            words = baseWords
        case .shuffle:
            words = baseWords.shuffled()
        case .weak:
            // due優先 + 高頻度優先の並び（視覚的な並びのみ。実出題は動的セレクタで決定）
            let dueSet = Set(srs.dueWords(from: baseWords).map { $0.id })
            words = baseWords.sorted { a, b in
                let aDue = dueSet.contains(a.id)
                let bDue = dueSet.contains(b.id)
                if aDue != bDue { return aDue && !bDue }
                let ar = a.freqRank ?? Int.max
                let br = b.freqRank ?? Int.max
                if ar != br { return ar < br }
                return a.term.localizedCaseInsensitiveCompare(b.term) == .orderedAscending
            }
        }
        if words.isEmpty { index = -1 } else { index = max(0, min(index, words.count - 1)) }
    }

    @MainActor func updateOrder(_ newRaw: String) {
        orderRaw = newRaw
        applyOrdering()
    }

    // MARK: - セッション配分
    private func rebuildQuota() {
        let total = max(1, sessionGoal)
        var sr = max(0, min(100, shareReview))
        var sl = max(0, min(100, shareRelearn))
        var sn = max(0, min(100, shareNew))
        // 合計100に寄せる
        let sum = max(1, sr + sl + sn)
        sr = Int(round(Double(total) * Double(sr) / Double(sum)))
        sl = Int(round(Double(total) * Double(sl) / Double(sum)))
        sn = max(0, total - sr - sl)
        quota = SessionQuota(goal: total, done: 0, reviewQuota: sr, relearnQuota: sl, newQuota: sn)
    }

    // MARK: - 操作（SRS OFF）
    @MainActor func reveal() { showMeaning = true }

    @MainActor
    func next() {
        markCurrentAsSeen()
        guard !words.isEmpty else { return }
        if index < 0 { index = 0 }

        let nextIndex = index + 1
        if nextIndex < words.count {
            index = nextIndex
            showMeaning = false
        } else {
            index = -1
            showMeaning = false
            finishedNonSRS = true
        }
        ProgressStore.shared.currentIndex = max(0, index)
        if let file = packFilename { up.setLastIndex(index, for: file) }
    }

    // MARK: - 操作（SRS ON, ソフトキュー）
    @MainActor
    func review(correct: Bool) {
        markCurrentAsSeen()
        guard let w = current else { return }

        // SRS 反映
        srs.mark(id: w.id, correct: correct)

        // 統計（簡易：NG を再学習へ寄せる）
        if correct {
            StudyStatsStore.shared.bumpReview(correct: true)
        } else {
            StudyStatsStore.shared.bumpReview(correct: false)
            // 誤答は短期的に再提示するためスタックへ
            mistakes.pushBack(w.id)
        }

        loadNextDue()
        if let file = packFilename { up.setLastIndex(index, for: file) }
    }

    @MainActor func nextDue() { loadNextDue() }

    /// 動的セレクタ：誤答 > due > 再学習 > 新規 > 補充
    @MainActor
    private func loadNextDue() {
        guard srsEnabled else { return } // 非SRSモードでは使わない
        guard !words.isEmpty else { index = -1; return }

        let curID = current?.id

        // 1) 誤答スタック
        if let w = mistakes.popNext(in: words, notSameAs: curID) {
            moveTo(w.id)
            showMeaning = false
            quota.bump(.relearn) // 誤答は再学習枠に計上
            return
        }

        // SRS 状態を軽く参照
        func rec(_ w: VocabWord) -> SRSRecord { srs.meta(for: w) }

        // プール
        let due = srs.dueWords(from: words)
        let relearn = words.filter { rec($0).lastWrong && rec($0).bucket > 0 }
        let newOnes = words.filter { rec($0).bucket == 0 }

        // ソート方針（高頻度優先→term）
        func sortPref(_ arr: [VocabWord]) -> [VocabWord] {
            if highFreqFirst {
                return arr.sorted {
                    let ar = $0.freqRank ?? Int.max
                    let br = $1.freqRank ?? Int.max
                    if ar != br { return ar < br }
                    return $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending
                }
            } else {
                return arr
            }
        }

        // 2) due
        if quota.allows(.review) {
            let cand = sortPref(due).first { $0.id != curID }
            if let t = cand {
                moveTo(t.id)
                showMeaning = false
                quota.bump(.review)
                return
            }
        }

        // 3) 再学習
        if quota.allows(.relearn) {
            let cand = sortPref(relearn).first { $0.id != curID }
            if let t = cand {
                moveTo(t.id)
                showMeaning = false
                quota.bump(.relearn)
                return
            }
        }

        // 4) 新規
        if quota.allows(.new) {
            let cand = sortPref(newOnes).first { $0.id != curID }
            if let t = cand {
                moveTo(t.id)
                showMeaning = false
                quota.bump(.new)
                return
            }
        }

        // 5) 補充（なんでも）
        if let any = words.first(where: { $0.id != curID }) {
            moveTo(any.id)
            showMeaning = false
            quota.bump(.fallback)
        } else {
            index = -1
            showMeaning = false
        }
    }

    private func moveTo(_ id: String) {
        if let i = words.firstIndex(where: { $0.id == id }) {
            index = i
            ProgressStore.shared.currentIndex = index
        }
    }

    // MARK: - ランダム（SRS無視）
    @MainActor
    func pickRandomIgnoringSRS() {
        guard !words.isEmpty else { return }
        if let w = words.randomElement(),
           let i = words.firstIndex(where: { $0.id == w.id }) {
            index = i
            showMeaning = false
            ProgressStore.shared.currentIndex = index
            if let file = packFilename { up.setLastIndex(index, for: file) }
        }
    }

    // MARK: - SRS整列（起動時）
    @MainActor
    func alignToSRSIfNeeded() {
        guard srsEnabled else { return }
        if current == nil {
            loadNextDue()
        } else {
            // 現在語が due でなければ “次の最適” へ
            if let cur = current, srs.dueWords(from: [cur]).isEmpty {
                loadNextDue()
            }
        }
    }

    // MARK: - 検索ジャンプ（既存）
    @MainActor
    func jump(toTerm term: String) {
        guard let idx = words.firstIndex(where: {
            $0.term.compare(term, options: .caseInsensitive) == .orderedSame
        }) else { return }
        index = idx
        showMeaning = false
        if let file = packFile { UnitProgressStore.shared.setLastIndex(index, for: file) }
    }

    // MARK: - NonSRS 進行（既存）
    @MainActor
    func nextNonSRS() {
        markCurrentAsSeen()
        guard !words.isEmpty else { return }
        if index + 1 < words.count {
            index += 1; showMeaning = false
        } else {
            index = -1; showMeaning = false; finishedNonSRS = true
        }
    }

    // MARK: - Helper
    private func markCurrentAsSeen() {
        guard let file = packFilename, let w = current else { return }
        up.markSeen(id: w.id, pack: file)
        up.setLastIndex(index, for: file)
    }

    private func applyFilters(to all: [VocabWord]) -> [VocabWord] {
        let topics = Set(
            topicsCSV
                .split(whereSeparator: { [",", " ", "、"].contains($0) })
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
        return all.filter { w in
            if cefrFilter != "All", (w.cefr ?? "") != cefrFilter { return false }
            if highFreqOnly, let r = w.freqRank, r > 5000 { return false }
            if !topics.isEmpty {
                let wTopics = Set((w.topics ?? []).map { $0.lowercased() })
                if wTopics.isDisjoint(with: topics) { return false }
            }
            return true
        }
    }
}

// 再学習（同順/シャッフル）（既存）
extension WordTrainerViewModel {
    @MainActor
    func restart(shuffled: Bool) {
        finishedNonSRS = false
        showMeaning = false
        if shuffled { words.shuffle() } else { applyOrdering() }
        index = words.isEmpty ? -1 : 0
        if let file = packFilename { up.setLastIndex(index, for: file) }
        rebuildQuota()
    }
}

