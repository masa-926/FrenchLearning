//
//  Prononcer.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/09/03.
//

import Foundation
import AVFoundation

@MainActor
final class Pronouncer: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Pronouncer()
    private let synth = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synth.delegate = self
        // 再生を他アプリとミックス。失敗しても致命的ではないので握りつぶし
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// フランス語の発音（必要なら lang を "ja-JP" などに変更可）
    func speak(_ text: String, lang: String = "fr-FR",
               rate: Float = AVSpeechUtteranceDefaultSpeechRate * 0.9) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }

        let utt = AVSpeechUtterance(string: t)
        utt.voice = AVSpeechSynthesisVoice(language: lang) ?? AVSpeechSynthesisVoice(language: "fr-FR")
        utt.rate  = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utt.pitchMultiplier = 1.0
        synth.speak(utt)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    // Delegate stubs（必要ならハンドリングを追加）
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {}
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {}
}

