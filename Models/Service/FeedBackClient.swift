//
//  FeedBackClient.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//
import Foundation
import UIKit
import os

struct FeedbackItem: Codable, Identifiable, Equatable {
    let id: String
    let date: Date
    let category: String
    let message: String
    let contact: String?
    let appVersion: String
    let device: String
}

final class FeedbackClient {
    static let shared = FeedbackClient()
    private let log = Logger(subsystem: Log.subsystem, category: "feedback")
    private let defaults = UserDefaults.standard
    private let queueKey = "feedback.queue"

    // 設定で保存された Formspree Endpoint
    private var endpoint: String? {
        defaults.string(forKey: "feedback.endpoint")?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // オフライン保留キュー
    private var queued: [FeedbackItem] {
        get {
            if let data = defaults.data(forKey: queueKey),
               let arr = try? JSONDecoder().decode([FeedbackItem].self, from: data) { return arr }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: queueKey)
            }
        }
    }

    func enqueue(_ item: FeedbackItem) {
        var q = queued
        q.append(item)
        queued = q
        log.info("queued feedback id=\(item.id, privacy: .public)")
    }

    func flushQueueIfPossible() async {
        guard let urlStr = endpoint, let url = URL(string: urlStr), !queued.isEmpty else { return }
        var remain: [FeedbackItem] = []
        for item in queued {
            do { try await post(item, to: url) }
            catch { remain.append(item) }
        }
        queued = remain
        log.info("flush finished; remaining=\(remain.count, privacy: .public)")
    }

    func submit(category: String, message: String, contact: String?) async throws {
        guard
            let urlStr = endpoint, let url = URL(string: urlStr),
            !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw NSError(domain: "Feedback", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "エンドポイント未設定または本文が空です。設定＞フィードバックでURLを追加してください。"])
        }
        let item = buildItem(category: category, message: message, contact: contact)
        try await post(item, to: url)
    }

    private func post(_ item: FeedbackItem, to url: URL) async throws {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "category": item.category,
            "message": item.message,
            "contact": item.contact as Any,
            "_subject": "[FrenchLearning] \(item.category)",
            "_format": "json",
            "appVersion": item.appVersion,
            "device": item.device,
            "createdAt": ISO8601DateFormatter().string(from: item.date)
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse,
              (200...299).contains(http.statusCode) || http.statusCode == 302 else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "Feedback", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "送信失敗(\((resp as? HTTPURLResponse)?.statusCode ?? -1))：\(text)"])
        }
        log.info("feedback posted ok")
    }

    // 同一ファイル内のextから呼べるのでprivateでOK
    private func buildItem(category: String, message: String, contact: String?) -> FeedbackItem {
        let ver = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")
        + " (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"))"
        let device = UIDevice.current.model + " / " + UIDevice.current.systemName + " " + UIDevice.current.systemVersion
        return FeedbackItem(
            id: UUID().uuidString,
            date: Date(),
            category: category,
            message: message,
            contact: (contact?.isEmpty == true) ? nil : contact,
            appVersion: ver,
            device: device
        )
    }
}


// buildForQueue（オフライン保留用）
extension FeedbackClient {
    func buildForQueue(category: String, message: String, contact: String?) -> FeedbackItem {
        buildItem(category: category, message: message, contact: contact)
    }
}
