// Features/Home/StatsMiniDashboard.swift
import SwiftUI

struct StatsMiniDashboard: View {
    @ObservedObject private var stats = StudyStatsStore.shared
    @State private var showSheet = false

    var body: some View {
        HStack(spacing: 10) {
            statChip("新規", stats.todayNew)
            statChip("復習OK", stats.todayReviewOK)
            statChip("復習NG", stats.todayReviewNG)
            statChip("再学習", stats.todayRelearn)
            Button {
                showSheet = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 4)
        .sheet(isPresented: $showSheet) { StatsDetailSheet() }
        .onReceive(NotificationCenter.default.publisher(for: .statsDidUpdate)) { _ in
            // Published があるので何もしなくてもUIは更新されるが、
            // 明示的にトリガーしたい場合のフックとして保持
        }
    }

    private func statChip(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.caption2)
            Text("\(value)").font(.headline)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.thinMaterial, in: Capsule())
    }
}

private struct StatsDetailSheet: View {
    @ObservedObject private var stats = StudyStatsStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("本日の学習") {
                    row("新規", stats.todayNew)
                    row("復習OK", stats.todayReviewOK)
                    row("復習NG", stats.todayReviewNG)
                    row("再学習", stats.todayRelearn)
                }
                Section {
                    Button(role: .destructive) {
                        StudyStatsStore.shared.resetToday()
                    } label: {
                        Label("今日の統計をリセット", systemImage: "arrow.counterclockwise")
                    }
                }
                Section("ヒント") {
                    Text("弱点（復習NG）は「再学習」で早めに潰すと効果的です。")
                        .font(.footnote)
                }
            }
            .navigationTitle("学習統計")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

    private func row(_ title: String, _ value: Int) -> some View {
        HStack { Text(title); Spacer(); Text("\(value)") }
    }
}

