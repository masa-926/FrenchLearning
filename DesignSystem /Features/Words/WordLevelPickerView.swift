//  WordLevelPickerView.swift
//  FrenchLearning

import SwiftUI

struct WordLevelPickerView: View {
    private let levels = CEFRLevel.allCases

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(levels, id: \.self) { lv in
                    NavigationLink {
                        WordUnitListView(level: lv)
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: bgColors(for: lv),
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 120)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lv.rawValue).font(.largeTitle.bold())
                                Text(levelCaption(lv)).font(.caption).opacity(0.9)
                            }
                            .padding(12)
                            .foregroundStyle(.white)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("レベルを選択")
    }

    // MARK: - Helpers
    private func bgColors(for lv: CEFRLevel) -> [Color] {
        switch lv {
        case .A1: return [.green, .teal]
        case .A2: return [.blue, .cyan]
        case .B1: return [.purple, .pink]
        case .B2: return [.orange, .red]
        case .C1: return [.indigo, .blue]
        case .C2: return [.gray, .black.opacity(0.7)]
        }
    }
    private func levelCaption(_ lv: CEFRLevel) -> String {
        switch lv {
        case .A1: return "基礎：挨拶・身近な語彙"
        case .A2: return "初級：日常の定型表現"
        case .B1: return "中級：身近な話題を説明"
        case .B2: return "中上級：抽象的な話題"
        case .C1: return "上級：高度な運用"
        case .C2: return "最上級：母語話者に近い"
        }
    }
}

struct WordUnitListView: View {
    let level: CEFRLevel

    @State private var packs: [VocabPack] = []
    @State private var percents: [String:Int] = [:]          // filename -> %
    @State private var plans: [String:TodayPlan] = [:]       // filename -> plan

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List(packs) { pack in
            NavigationLink {
                WordUnitIntroView(packFilename: pack.filename)
             } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(pack.title).font(.headline)
                        Text(pack.filename).font(.caption).foregroundStyle(.secondary)

                        // 追加：今日のプラン表示（復習／再学習／新出）
                        if let plan = plans[pack.filename] {
                            HStack(spacing: 10) {
                                PlanDot(color: .blue,   label: "復習",   count: plan.reviewIDs.count)
                                PlanDot(color: .orange, label: "再学習", count: plan.relearnIDs.count)
                                PlanDot(color: .green,  label: "新出",   count: plan.newIDs.count)
                            }
                            .font(.caption)
                        }
                    }
                    Spacer()
                    if let p = percents[pack.filename] {
                        PercentBadge(percent: p)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        // WordLevelPickerView の body 末尾 .navigationTitle の後ろあたりに
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SearchView() } label: {
                    Label("検索", systemImage: "magnifyingglass")
                }
            }
        }

        .listStyle(.insetGrouped)
        .navigationTitle("\(level.rawValue) のユニット")
        .onAppear { reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reload() }  // 学習から戻ったら再計算
        }
        // SRS更新の通知でも再計算（SRSStore で .srsDidUpdate を定義済みの想定）
        .onReceive(NotificationCenter.default.publisher(for: .srsDidUpdate)) { _ in
            reload()
        }
    }

    // MARK: - Data
    private func reload() {
        let map = VocabCatalog.shared.packsByLevel()
        packs = map[level] ?? []
        computePercentsAndPlans()
    }

    private func computePercentsAndPlans() {
        var tmpPcts: [String:Int] = [:]
        var tmpPlans: [String:TodayPlan] = [:]

        for pack in packs {
            let words = VocabLoader.shared.load(fileNamed: pack.filename)

            // ％
            let total = max(1, words.count)
            let seen = UnitProgressStore.shared.seenCount(for: pack.filename)
            tmpPcts[pack.filename] = Int((Double(seen) / Double(total) * 100).rounded())

            // 今日のプラン
            let plan = PlanBuilder.shared.buildPlan(for: pack.filename, words: words)
            tmpPlans[pack.filename] = plan
        }

        percents = tmpPcts
        plans = tmpPlans
    }
}// === ここから追記 ===

public extension PlanBuilder {
    /// シングルトン的に使いたい場合のエイリアス
    static let shared = PlanBuilder()

    /// WordLevelPickerView から使いやすいラッパー
    /// - Parameters:
    ///   - filename: パックファイル名（現状未使用・将来拡張用）
    ///   - words: そのパックに含まれる単語
    ///   - learning/review/relearning: 取り出す件数
    func buildPlan(
        for filename: String,
        words: [VocabWord],
        learning: Int = 10,
        review: Int = 20,
        relearning: Int = 10
    ) -> TodayPlan {
        let adapter = SRSProgressAdapter(words: words)
        return build(
            loadedIDs: words.map(\.id),         // ← String ID に統一
            progress: adapter,
            learning: learning,
            review: review,
            relearning: relearning
        )
    }
}

/// SRS の状態から ProgressReading を作る軽量アダプタ
private struct SRSProgressAdapter: ProgressReading {
    let wrongWordIDs: Set<String>
    let dueReviewIDs: [String]

    init(words: [VocabWord]) {
        // いまは「期限が来た復習」だけ SRS から拾う。誤答ログ等があればここに追加。
        let due = SRSStore.shared.dueWords(from: words).map { $0.id }
        self.dueReviewIDs = due
        self.wrongWordIDs = []  // TODO: 誤答履歴があればここでセット
    }
}
// === 追記ここまで ===


private struct PlanDot: View {
    let color: Color
    let label: String
    let count: Int
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
            Text("\(count)").bold()
        }
    }
}

