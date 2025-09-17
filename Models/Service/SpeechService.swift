import Foundation
import AVFoundation

public final class Pronouncer: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = Pronouncer()
    private let synth = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synth.delegate = self
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // 失敗は致命的でないので無視
        }
    }

    /// フランス語の発音
    public func speak(_ text: String, lang: String = "fr-FR",
                      rate: Float = AVSpeechUtteranceDefaultSpeechRate * 0.9) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }

        let u = AVSpeechUtterance(string: t)
        u.voice = AVSpeechSynthesisVoice(language: lang) ?? AVSpeechSynthesisVoice(language: "fr-FR")
        u.rate  = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        u.pitchMultiplier = 1.0
        synth.speak(u)
    }

    public func stop() { synth.stopSpeaking(at: .immediate) }

    // Delegate（必要なら拡張）
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {}
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {}
}

