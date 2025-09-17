// Features/Stats/StudyStatsView.swift
import SwiftUI

// 最低限の表示用サマリ型（あとでプロジェクトの型に合わせて移設OK）
struct DaySummary: Identifiable {
    let id = UUID()
    var new: Int
    var reviewOK: Int
    var reviewNG: Int
    var relearn: Int
}

struct StudyStatsView: View {
    @State private var today: DaySummary = StudyStatsStore.shared.todayCounts()
    @State private var week:  [DaySummary] = StudyStatsStore.shared.weeklyCounts()

    var body: some View {
        List {
            Section("今日") {
                LabeledContent("新出", value: "\(today.new)")
                LabeledContent("復習 正解", value: "\(today.reviewOK)")
                LabeledContent("復習 誤答", value: "\(today.reviewNG)")
                LabeledContent("再学習", value: "\(today.relearn)")
            }
            Section("今週（合計）") {
                let sum = week.reduce((0,0,0,0)) { acc, d in
                    (acc.0 + d.new, acc.1 + d.reviewOK, acc.2 + d.reviewNG, acc.3 + d.relearn)
                }
                LabeledContent("新出", value: "\(sum.0)")
                LabeledContent("復習 正解", value: "\(sum.1)")
                LabeledContent("復習 誤答", value: "\(sum.2)")
                LabeledContent("再学習", value: "\(sum.3)")
            }
        }
        .navigationTitle("学習統計")
        .onAppear {
            today = StudyStatsStore.shared.todayCounts()
            week  = StudyStatsStore.shared.weeklyCounts()
        }
    }
}

// --- 暫定シム（本実装が無ければ使われます。後で置き換えてOK） ---
extension StudyStatsStore {
    func todayCounts() -> DaySummary {
        // TODO: 実ロジックに差し替え
        DaySummary(new: 0, reviewOK: 0, reviewNG: 0, relearn: 0)
    }

    func weeklyCounts() -> [DaySummary] {
        // TODO: 実ロジックに差し替え（7日分を返す）
        Array(repeating: DaySummary(new: 0, reviewOK: 0, reviewNG: 0, relearn: 0), count: 7)
    }
}

