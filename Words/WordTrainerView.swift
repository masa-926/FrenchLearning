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
    @State private var lastSpokenWordID: String? = nil   // ← 追加

    var body: some View {
        VStack(spacing: 24) {
            if let w = vm.current {
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
        .onAppear {
            if let w = vm.current, lastSpokenWordID == nil {
                lastSpokenWordID = w.id
                SpeechService.shared.speak(w.term, lang: SpeechService.prefLang)
            }
        }
        .onChange(of: vm.current?.id) { newID in
            guard let id = newID, id != lastSpokenWordID, let w = vm.current else { return }
            lastSpokenWordID = id
            SpeechService.shared.speak(w.term, lang: SpeechService.prefLang)
        }
        .onDisappear { SpeechService.shared.stop() }
    }
}
