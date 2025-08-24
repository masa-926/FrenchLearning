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

    // 音声設定
    @AppStorage("tts.enabled") private var ttsEnabled: Bool = true
    @AppStorage("tts.autoplay") private var ttsAutoplay: Bool = true
    @AppStorage("tts.lang") private var ttsLang: String = "fr-FR"
    @AppStorage("tts.rate") private var ttsRate: Double = 0.45

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

            Section("音声（単語カード）") {
                Toggle("読み上げを有効にする", isOn: $ttsEnabled)
                Toggle("単語を表示したら自動で発音", isOn: $ttsAutoplay)

                Picker("言語", selection: $ttsLang) {
                    Text("フランス語（フランス）").tag("fr-FR")
                    Text("フランス語（カナダ）").tag("fr-CA")
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Slider(value: $ttsRate, in: 0.2...0.6, step: 0.05)
                    Text("速度: \(String(format: "%.2f", ttsRate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    SpeechService.shared.speak("Bonjour ! Je suis ravi de vous aider.", lang: ttsLang)
                } label: {
                    Label("プレビュー再生", systemImage: "play.circle")
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
