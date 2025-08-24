//
//  SpeechService.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation
import AVFoundation

final class SpeechService {
    static let shared = SpeechService()
    private let synth = AVSpeechSynthesizer()

    static var prefLang: String {
        UserDefaults.standard.string(forKey: "tts.lang") ?? "fr-FR"
    }

    func speak(_ text: String, lang: String = SpeechService.prefLang) {
        // 設定でOFFなら何もしない
        if UserDefaults.standard.object(forKey: "tts.enabled") == nil {
            UserDefaults.standard.set(true, forKey: "tts.enabled") // 初期値ON
        }
        guard UserDefaults.standard.bool(forKey: "tts.enabled") else { return }

        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)

        // 言語（デフォ fr-FR）
        u.voice = AVSpeechSynthesisVoice(language: lang)
            ?? AVSpeechSynthesisVoice(language: "fr-FR")

        // 速度（0.2〜0.6の範囲で保存、デフォ0.45）
        let saved = UserDefaults.standard.double(forKey: "tts.rate")
        let rate = (saved == 0) ? 0.45 : min(max(saved, 0.2), 0.6)
        u.rate = Float(rate)

        u.pitchMultiplier = 1.0
        u.volume = 1.0
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}

