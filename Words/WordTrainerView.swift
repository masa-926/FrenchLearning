//
//  WordTrainerView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

// Features/Words/WordTrainerView.swift

import SwiftUI

struct WordTrainerView: View {
    @StateObject var vm = WordTrainerViewModel()

    // 自動発音の設定＋多重再生防止
    @AppStorage("tts.autoplay") private var ttsAutoplay: Bool = true
    @State private var lastSpokenWordID: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            if let w = vm.current {
                // 単語＋スピーカー
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(w.term)
                        .font(.system(size: 40, weight: .bold))
                        .padding(.top, 32)

                    Button {
                        SpeechService.shared.speak(w.term, lang: SpeechService.prefLang)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill").font(.title2)
                    }
                    .accessibilityLabel("発音を再生")
                }

                // 意味・例文
                if vm.showMeaning {
                    VStack(spacing: 8) {
                        Text(w.meaningJa).font(.title2)
                        if let ex = w.example, !ex.isEmpty {
                            Text(ex).font(.body).foregroundStyle(.secondary)
                            Button {
                                SpeechService.shared.speak(ex, lang: SpeechService.prefLang)
                            } label: {
                                Label("例文を再生", systemImage: "speaker.wave.2")
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 4)
                        }
                    }
                    .transition(.opacity)
                } else {
                    Button("意味を表示") { vm.reveal() }
                        .buttonStyle(.borderedProminent)
                }

                Button("次へ") {
                    SpeechService.shared.stop()
                    vm.next()
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)

                Spacer()
            } else {
                Text("単語データが読み込めませんでした。")
            }
        }
        .padding()
        .navigationTitle("単語学習")

        // 画面表示時：現在の単語を1回だけ自動発音
        .onAppear {
            guard ttsAutoplay, let w = vm.current, lastSpokenWordID == nil else { return }
            lastSpokenWordID = w.id
            SpeechService.shared.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                SpeechService.shared.speak(w.term, lang: SpeechService.prefLang)
            }
        }

        // iOS 17 の新API版 onChange（旧版は非推奨）
        .onChange(of: vm.current?.id, initial: false) { _, newID in
            guard ttsAutoplay, let id = newID, id != lastSpokenWordID, let w = vm.current else { return }
            lastSpokenWordID = id
            SpeechService.shared.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                SpeechService.shared.speak(w.term, lang: SpeechService.prefLang)
            }
        }

        .onDisappear { SpeechService.shared.stop() }
    }
}
