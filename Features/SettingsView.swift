//
//  Features:Settings:SettingsView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//
import SwiftUI

struct SettingsView: View {
    @AppStorage("openai.apiKey") private var apiKey: String = ""
    @AppStorage("openai.mockEnabled") private var mockEnabled: Bool = false
    @AppStorage("openai.dailyLimit") private var dailyLimit: Int = 20

    var body: some View {
        Form {
            Section("OpenAI") {
                SecureField("APIキー", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                Text(apiKey.isEmpty ? "未設定" : "設定済み")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("利用制限") {
                Stepper("1日の上限: \(dailyLimit) 回", value: $dailyLimit, in: 1...200)
                Text("本日の残り: \(DailyQuotaStore.shared.remaining(limit: dailyLimit)) 回")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("今日のカウントをリセット") {
                    DailyQuotaStore.shared.resetToday()
                }
            }
            Section("開発用") {
                Toggle("AIをモックで動かす", isOn: $mockEnabled)
            }
            Section {
                Button(role: .destructive) {
                    ProgressStore.shared.currentIndex = 0
                } label: {
                    Text("単語学習の進捗をリセット")
                }
            }
        }
        .navigationTitle("設定")
    }
}
