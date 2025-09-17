import Foundation

public struct VerbPattern: Identifiable, Hashable, Codable {
    public var id: String { lemma + "|" + preposition + "|" + complement }
    public let lemma: String
    public let preposition: String
    public let complement: String
    public let example: String
    public let count: Int
    public let source: String?   // 出典表示用
}

public final class UDPatternStore {
    public static let shared = UDPatternStore()
    private var patternsByLemma: [String:[VerbPattern]] = [:]

    private init() {
        if let url = Bundle.main.url(forResource: "ud_patterns_min", withExtension: "csv"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            loadCSV(text)
        } else {
            let fallback: [VerbPattern] = [
                VerbPattern(lemma: "aller", preposition: "à", complement: "lieu",
                            example: "Je vais à l'école.", count: 120, source: "UD(GSD/Sequoia)"),
                VerbPattern(lemma: "penser", preposition: "à", complement: "qqch/qqn",
                            example: "Je pense à toi.", count: 95, source: "UD(GSD)"),
                VerbPattern(lemma: "penser", preposition: "de", complement: "opinion",
                            example: "Qu'est-ce que tu penses de ce film ?", count: 60, source: "UD(GSD)"),
                VerbPattern(lemma: "se souvenir", preposition: "de", complement: "qqch",
                            example: "Je me souviens de notre voyage.", count: 80, source: "UD(Sequoia)")
            ]
            patternsByLemma = Dictionary(grouping: fallback, by: { $0.lemma.lowercased() })
        }
    }

    private func loadCSV(_ text: String) {
        var rows: [VerbPattern] = []
        for line in text.split(separator: "\n") {
            let raw = line.trimmingCharacters(in: .whitespaces)
            if raw.isEmpty || raw.hasPrefix("#") { continue }
            // lemma,preposition,complement,example,count,source?
            let cols = splitCSV(String(raw))
            guard cols.count >= 5 else { continue }
            let lemma = cols[0]
            let prep  = cols[1]
            let comp  = cols[2]
            let ex    = cols[3]
            let cnt   = Int(cols[4]) ?? 1
            let src   = (cols.count >= 6) ? cols[5] : nil
            rows.append(VerbPattern(lemma: lemma, preposition: prep, complement: comp, example: ex, count: cnt, source: src))
        }
        patternsByLemma = Dictionary(grouping: rows, by: { $0.lemma.lowercased() })
    }

    private func splitCSV(_ s: String) -> [String] {
        var res: [String] = []
        var cur = ""
        var inQ = false
        for c in s {
            if c == "\"" { inQ.toggle(); continue }
            if c == "," && !inQ {
                res.append(cur.trimmingCharacters(in: .whitespaces))
                cur = ""
            } else {
                cur.append(c)
            }
        }
        res.append(cur.trimmingCharacters(in: .whitespaces))
        return res
    }

    public func patterns(for lemma: String) -> [VerbPattern] {
        let key = LefffConjugator.normalizeLemma(lemma)
        let a = patternsByLemma[key] ?? []
        let b = patternsByLemma[lemma.lowercased()] ?? []
        return a.isEmpty ? b : a
    }
}

