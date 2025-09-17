import Foundation

public struct VerbConjugation: Codable, Hashable {
    public let lemma: String
    public let mood: String      // indicatif, subjonctif, conditionnel, impératif, participe, infinitif …
    public let tense: String     // présent, imparfait, futur, passé composé など
    public let forms: [String:String] // "je": "vais", "tu": "vas" …
}

public final class LefffConjugator {
    public static let shared = LefffConjugator()

    private var byLemma: [String:[VerbConjugation]] = [:]

    private init() {
        if let url = Bundle.main.url(forResource: "lefff_verbs_min", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([VerbConjugation].self, from: data) {
            byLemma = Dictionary(grouping: items, by: { Self.normalizeLemma($0.lemma) })
            return
        }

        // フォールバック（UI検証用）
        let fallback: [VerbConjugation] = [
            VerbConjugation(
                lemma: "aller", mood: "indicatif", tense: "présent",
                forms: ["je":"vais","tu":"vas","il/elle":"va","nous":"allons","vous":"allez","ils/elles":"vont"]
            ),
            VerbConjugation(
                lemma: "être", mood: "indicatif", tense: "présent",
                forms: ["je":"suis","tu":"es","il/elle":"est","nous":"sommes","vous":"êtes","ils/elles":"sont"]
            ),
            VerbConjugation(
                lemma: "avoir", mood: "indicatif", tense: "présent",
                forms: ["j'":"ai","tu":"as","il/elle":"a","nous":"avons","vous":"avez","ils/elles":"ont"]
            ),
            VerbConjugation(
                lemma: "aller", mood: "impératif", tense: "présent",
                forms: ["tu":"va","nous":"allons","vous":"allez"]
            )
        ]
        byLemma = Dictionary(grouping: fallback, by: { Self.normalizeLemma($0.lemma) })
    }

    public static func normalizeLemma(_ lemma: String) -> String {
        lemma.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "^se\\s+", with: "", options: .regularExpression) // se souvenir -> souvenir
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func conjugations(for lemma: String) -> [VerbConjugation] {
        let key = Self.normalizeLemma(lemma)
        if let v = byLemma[key] { return v }
        return byLemma[lemma.lowercased()] ?? []
    }
}

