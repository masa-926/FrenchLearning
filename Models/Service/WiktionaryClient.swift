//
//  WiktionaryClient.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/31.
//

import Foundation

public struct WiktionaryEntry: Codable {
    public let title: String
    public let extractHTML: String  // 短い抜粋（HTML）
    public let revisionID: Int?
}

public final class WiktionaryClient {
    public static let shared = WiktionaryClient()
    private init() {}

    private let session = URLSession(configuration: .default)

    // 簡易キャッシュ（Documents/wiktionary/<title>.json）
    private var cacheDir: URL? = {
        try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("wiktionary", isDirectory: true)
    }()

    public func fetchShortExtract(for term: String) async throws -> WiktionaryEntry? {
        let key = term.replacingOccurrences(of: "/", with: "_")
        if let cached = try? loadCache(for: key) { return cached }

        // fr.wiktionary.org の MediaWiki API (extracts)
        var comps = URLComponents(string: "https://fr.wiktionary.org/w/api.php")!
        comps.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "prop", value: "extracts|info"),
            .init(name: "exintro", value: "1"),
            .init(name: "explaintext", value: "0"), // HTMLで受け取る
            .init(name: "inprop", value: "url"),
            .init(name: "format", value: "json"),
            .init(name: "titles", value: term)
        ]
        let (data, _) = try await session.data(from: comps.url!)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let query = obj?["query"] as? [String: Any],
            let pages = query["pages"] as? [String: Any],
            let first = pages.values.first as? [String: Any],
            let title = first["title"] as? String,
            let extract = first["extract"] as? String
        else { return nil }

        let rev = first["lastrevid"] as? Int
        let entry = WiktionaryEntry(title: title, extractHTML: extract, revisionID: rev)
        try? saveCache(entry, for: key)
        return entry
    }

    private func cacheURL(for key: String) -> URL? {
        guard let dir = cacheDir else { return nil }
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("\(key).json")
    }

    private func saveCache(_ entry: WiktionaryEntry, for key: String) throws {
        guard let url = cacheURL(for: key) else { return }
        let data = try JSONEncoder().encode(entry)
        try data.write(to: url, options: .atomic)
    }

    private func loadCache(for key: String) throws -> WiktionaryEntry? {
        guard let url = cacheURL(for: key), FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(WiktionaryEntry.self, from: data)
    }
}

