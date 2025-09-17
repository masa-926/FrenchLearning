import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage("speech.lang")  private var speechLang: String  = "fr-FR"
    @AppStorage("speech.rate")  private var speechRate: Double  = Double(AVSpeechUtteranceDefaultSpeechRate) * 0.9
    @AppStorage("speech.pitch") private var speechPitch: Double = 1.0

    private let supportedLangs = [
        ("フランス（標準）", "fr-FR"),
        ("カナダ", "fr-CA")
    ]

    var body: some View {
        List {
            Section("発音（TTS）") {
                Picker("言語", selection: $speechLang) {
                    ForEach(supportedLangs, id: \.1) { item in
                        Text(item.0).tag(item.1)
                    }
                }

                VStack(alignment: .leading) {
                    Text("速度").font(.subheadline)
                    Slider(
                        value: $speechRate,
                        in: Double(AVSpeechUtteranceMinimumSpeechRate)...Double(AVSpeechUtteranceMaximumSpeechRate),
                        step: 0.01
                    )
                    Text(String(format: "%.2f", speechRate))
                        .font(.caption).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    Text("ピッチ").font(.subheadline)
                    Slider(value: $speechPitch, in: 0.5...2.0, step: 0.01)
                    Text(String(format: "%.2f", speechPitch))
                        .font(.caption).foregroundStyle(.secondary)
                }

                Button {
                    // Pronouncer の rate は Float? なので変換して渡す
                    Pronouncer.shared.speak("bonjour, enchanté",
                                           lang: speechLang,
                                           rate: Float(speechRate))
                } label: {
                    Label("テスト再生", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("設定")
    }
}

