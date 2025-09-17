import SwiftUI

struct TodayStartView: View {
    @AppStorage("study.dailyGoal") private var dailyGoal: Int = 20
    @AppStorage("srs.fast") private var srsFast: Bool = true

    // ソフトキューの方針（セッション配分）
    @AppStorage("session.goal") private var sessionGoal: Int = 20
    @AppStorage("session.share.review") private var shareReview: Int = 60
    @AppStorage("session.share.relearn") private var shareRelearn: Int = 20
    @AppStorage("session.share.new") private var shareNew: Int = 20
    @AppStorage("session.highFreqFirst") private var highFreqFirst: Bool = true

    @State private var suggestedPack: VocabPack?

    var body: some View {
        List {
            Section("今日の目標") {
                Stepper("回数 \(sessionGoal) 回", value: $sessionGoal, in: 5...200, step: 5)
                Toggle("テスト用に高速化（分単位）", isOn: $srsFast)
                Toggle("高頻度語を優先", isOn: $highFreqFirst)
            }

            Section("配分（合計100）") {
                HStack { Text("復習");     Spacer(); Text("\(shareReview)%") }
                Slider(value: Binding(
                    get: { Double(shareReview) },
                    set: { shareReview = Int($0.rounded()); normalizeShares() }
                ), in: 0...100, step: 1)

                HStack { Text("再学習");   Spacer(); Text("\(shareRelearn)%") }
                Slider(value: Binding(
                    get: { Double(shareRelearn) },
                    set: { shareRelearn = Int($0.rounded()); normalizeShares() }
                ), in: 0...100, step: 1)

                HStack { Text("新規");     Spacer(); Text("\(shareNew)%") }
                Text("自動で合計が100になるように調整されます。")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let pack = suggestedPack {
                Section("おすすめのユニット") {
                    NavigationLink {
                        WordTrainerView(packFilename: pack.filename, initialOrder: .weak)
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
                    WordTrainerView(packFilename: nil, initialOrder: .weak)
                } label: {
                    Label("今日の学習をはじめる", systemImage: "bolt.fill")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SearchView() } label: {
                    Label("検索", systemImage: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { AttributionsView() } label: {
                    Label("出典", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("今日の学習")
        .task { loadSuggestion() }
        .onAppear {
            // 旧キーからの移行（互換のため）
            dailyGoal = max(dailyGoal, 5)
            sessionGoal = dailyGoal
            normalizeShares()
        }
    }

    private func normalizeShares() {
        // 合計が100になるように寄せる（単純配分）
        let sum = max(1, shareReview + shareRelearn + shareNew)
        shareReview  = Int(round(Double(shareReview)  * 100.0 / Double(sum)))
        shareRelearn = Int(round(Double(shareRelearn) * 100.0 / Double(sum)))
        shareNew     = max(0, 100 - shareReview - shareRelearn)
    }

    private func loadSuggestion() {
        let map = VocabCatalog.shared.packsByLevel()
        let a2 = map[.A2] ?? map.values.flatMap { $0 }
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

