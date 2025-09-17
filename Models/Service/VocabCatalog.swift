import Foundation

struct VocabPack: Identifiable, Hashable {
    let id: String        // 例: "A1_u01"
    let level: CEFRLevel  // A1..C2
    let title: String     // 表示名（"Unit 01" など）
    let filename: String  // 実ファイル名（"wordset_A1_u01.json"）
    let count: Int?       // 既知なら件数、未定なら nil
}

final class VocabCatalog {
    static let shared = VocabCatalog()
    private init() {}

    func packsByLevel() -> [CEFRLevel: [VocabPack]] {
        var map: [CEFRLevel: [VocabPack]] = [:]
        let all = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)

        for path in all {
            let fname = (path as NSString).lastPathComponent
            guard fname.lowercased().hasPrefix("wordset_") else { continue }

            // 期待形式: wordset_<LEVEL>_<slug>.json
            let base = (fname as NSString).deletingPathExtension
            let comps = base.split(separator: "_")
            guard comps.count >= 3 else { continue }

            let levelStr = String(comps[1])
            guard let level = CEFRLevel(rawValue: levelStr) else { continue }

            let slug = comps.dropFirst(2).joined(separator: "_")
            let title = Self.makeTitle(from: slug)

            let id = "\(level.rawValue)_\(slug)"
            map[level, default: []].append(
                VocabPack(id: id, level: level, title: title, filename: fname, count: nil)
            )
        }

        for key in map.keys {
            map[key]?.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
        return map
    }

    private static func makeTitle(from slug: String) -> String {
        if slug.hasPrefix("u"), let num = Int(slug.dropFirst()) {
            return String(format: "Unit %02d", num)
        }
        if slug.lowercased() == "core" { return "Core" }
        return slug.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

