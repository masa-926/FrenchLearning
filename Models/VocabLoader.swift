//  VocabLoader.swift
//  FrenchLearning

import Foundation
import OSLog

final class VocabLoader {
    static let shared = VocabLoader()
    private let log = Logger(subsystem: "FrenchLearning", category: "VocabLoader")

    /// 指定ファイル名の語彙を読み込む。
    /// 例: "wordset_A2_u01.json" / "wordset_A2_u01"（拡張子省略OK）
    func load(fileNamed name: String) -> [VocabWord] {
        let ns = name as NSString
        let base = ns.deletingPathExtension
        let ext  = ns.pathExtension.isEmpty ? "json" : ns.pathExtension

        // 1) 正攻法（拡張子付き）
        if let url = Bundle.main.url(forResource: base, withExtension: ext) {
            return decode(url)
        }

        // 2) バンドル内の .json を総当たり（大文字小文字無視で一致）
        let all = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)

        if let path = all.first(where: {
            (( $0 as NSString ).lastPathComponent).lowercased() == name.lowercased()
        }) {
            return decode(URL(fileURLWithPath: path))
        }

        // 3) 拡張子を外して一致
        if let path = all.first(where: {
            ((( $0 as NSString ).lastPathComponent) as NSString)
                .deletingPathExtension.lowercased() == base.lowercased()
        }) {
            return decode(URL(fileURLWithPath: path))
        }

        // ← 補間の中で複雑に書かず、先に計算してからログに渡す
        let bundleList = all.map { ($0 as NSString).lastPathComponent }
                            .joined(separator: ", ")
        log.error("JSON not found for \(name, privacy: .public). Bundle JSONs: \(bundleList, privacy: .public)")
        return []
    }

    /// wordset_*.json を全て読み込んで結合（id と term で重複除去）
    func loadAll() -> [VocabWord] {
        var result: [VocabWord] = []
        let all = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)

        for path in all {
            let fname = (path as NSString).lastPathComponent.lowercased()
            guard fname.hasPrefix("wordset_") else { continue }
            result.append(contentsOf: decode(URL(fileURLWithPath: path)))
        }

        // 重複除去
        var seenIDs = Set<String>()
        var seenTerms = Set<String>()
        let dedup = result.compactMap { w -> VocabWord? in
            if seenIDs.contains(w.id) { return nil }
            let t = w.term.lowercased()
            if seenTerms.contains(t) { return nil }
            seenIDs.insert(w.id)
            seenTerms.insert(t)
            return w
        }

        log.info("Loaded \(dedup.count, privacy: .public) words (after dedup).")
        return dedup
    }

    // MARK: - decode helper
    private func decode(_ url: URL) -> [VocabWord] {
        do {
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode([VocabWord].self, from: data)
            log.debug("Decoded \(list.count, privacy: .public) words from \(url.lastPathComponent, privacy: .public)")
            return list
        } catch {
            let errStr = String(describing: error)
            log.error("Decode failed for \(url.lastPathComponent, privacy: .public): \(errStr, privacy: .public)")
            return []
        }
    }
}

