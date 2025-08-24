import SwiftUI

struct WordTrainerView: View {
    @StateObject var vm = WordTrainerViewModel()
    @AppStorage("srs.enabled") private var srsEnabled: Bool = true

    // 自動発音の設定＋多重再生防止
    @AppStorage("tts.autoplay") private var ttsAutoplay: Bool = true
    @State private var lastSpokenWordID: String? = nil

    // カウントダウン用
    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

                        // SRS 操作用
                        if srsEnabled {
                            HStack {
                                Button {
                                    Task { await MainActor.run { vm.review(correct: false) } }
                                } label: {
                                    Label("まだ", systemImage: "arrow.counterclockwise")
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)

                                Button {
                                    Task { await MainActor.run { vm.review(correct: true) } }
                                } label: {
                                    Label("覚えた", systemImage: "checkmark.circle")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 6)
                        }
                    }
                    .transition(.opacity)
                } else {
                    Button("意味を表示") { vm.reveal() }
                        .buttonStyle(.borderedProminent)
                }

                // 「次へ」：SRS有効なら次の復習、無効なら従来のnext()
                Button(srsEnabled ? "次の復習へ" : "次へ") {
                    if srsEnabled {
                        Task { await MainActor.run { vm.nextDue() } }
                    } else {
                        vm.next()
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)

                Spacer()

            } else {
                // ここに“待ち画面”を出す（SRS ON で単語はあるが current が無い＝今は復習なし）
                if srsEnabled, !vm.words.isEmpty {
                    VStack(spacing: 12) {
                        Text("今は復習対象がありません").font(.title3.bold())
                        if let next = SRSStore.shared.nextDueDate(from: vm.words, now: now) {
                            Text("次の復習まで: \(countdownString(to: next))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("しばらくしてからまた開いてください。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Button {
                                vm.pickRandomIgnoringSRS()   // すぐ学びたい
                            } label: {
                                Label("今すぐランダムで学習", systemImage: "sparkles")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                vm.alignToSRSIfNeeded()      // 再チェック
                            } label: {
                                Label("更新", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    Spacer()
                } else {
                    Text("単語データが読み込めませんでした。")
                    Spacer()
                }
            }
        }
        .padding()
        .navigationTitle("単語学習")

        // 初回表示：SRS整合＋自動発音1回
        .onAppear {
            vm.alignToSRSIfNeeded()
            if ttsAutoplay, let w = vm.current, lastSpokenWordID == nil {
                lastSpokenWordID = w.id
                SpeechService.shared.stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    SpeechService.shared.speak(w.term, lang: SpeechService.prefLang)
                }
            }
        }
        // カウントダウン更新
        .onReceive(tick) { now = $0 }

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

    // 残り時間を「hh:mm:ss / mm:ss / まもなく」で表示
    private func countdownString(to date: Date) -> String {
        let diff = Int(date.timeIntervalSince(now))
        if diff <= 0 { return "まもなく" }
        let h = diff / 3600
        let m = (diff % 3600) / 60
        let s = diff % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

