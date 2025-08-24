//
//  Features:Settings:SettingsView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("openai.apiKey") private var apiKey: String = ""

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
            Section {
                Button(role: .destructive) {
                    ProgressStore.shared.currentIndex = 0
                } label: { Text("単語学習の進捗をリセット") }
            }
        }
        .navigationTitle("設定")
    }
}
