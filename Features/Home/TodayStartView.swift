// Features/Home/TodayStartView.swift
import SwiftUI

struct TodayStartView: View {
    @AppStorage("study.dailyGoal") private var dailyGoal: Int = 20
    @AppStorage("srs.fast") private var srsFast: Bool = true
    @State private var suggestedPack: VocabPack?

    var body: some View {
        List {
            Section {
                Stepper("今日の目標 \(dailyGoal) 回", value: $dailyGoal, in: 5...200, step: 5)
                Toggle("テスト用に高速化（分単位）", isOn: $srsFast)
            }

            if let pack = suggestedPack {
                Section("おすすめのユニット") {
                    NavigationLink {
                        let plan = PlanBuilder.build(scope: .unit(filename: pack.filename),
                                                     goal: dailyGoal, fast: srsFast)
                        WordTrainerView(packFilename: pack.filename,
                                        initialOrder: .weak,
                                        initialPlan: plan)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pack.title).font(.headline)
                                Text(pack.filename).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            PercentBadge(percent: UnitPercent.forPack(pack.filename))
                        }
                    }
                }
            }

            Section("全ユニット横断で開始") {
                NavigationLink {
                    let plan = PlanBuilder.build(scope: .all, goal: dailyGoal, fast: srsFast)
                    WordTrainerView(packFilename: nil,
                                    initialOrder: .weak,
                                    initialPlan: plan)
                } label: {
                    Label("今日の学習をはじめる", systemImage: "bolt.fill")
                }
            }
        }
        .toolbar {
            // 🔍 検索
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SearchView() } label: {
                    Label("検索", systemImage: "magnifyingglass")
                }
            }
            // ℹ️ 出典/ライセンス
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { AttributionsView() } label: {
                    Label("出典", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("今日の学習")
        .task { loadSuggestion() }
    }

    private func loadSuggestion() {
        let map = VocabCatalog.shared.packsByLevel()
        let a2 = map[.A2] ?? map.values.flatMap { $0 }
        // いちばん due が多いユニットを提案
        suggestedPack = a2.max { a, b in
            let aw = VocabLoader.shared.load(fileNamed: a.filename)
            let bw = VocabLoader.shared.load(fileNamed: b.filename)
            return SRSStore.shared.dueWords(from: aw).count < SRSStore.shared.dueWords(from: bw).count
        }
    }
}

enum UnitPercent {
    static func forPack(_ filename: String) -> Int {
        let total = VocabLoader.shared.load(fileNamed: filename).count
        let seen  = UnitProgressStore.shared.seenCount(for: filename)
        guard total > 0 else { return 0 }
        return min(100, Int((Double(min(seen,total)) / Double(total) * 100).rounded()))
    }
}

