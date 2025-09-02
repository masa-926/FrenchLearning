import Foundation

// 例文: 文字列 or { "text": "...", "ja": "...", "tense": "..." } / { "fr": "..." }
public struct VocabExample: Codable, Hashable {
    public let text: String        // 例文（フランス語）
    public let tense: String?      // "présent", "passé composé" など
    public let ja: String?         // 日本語訳

    private enum CodingKeys: String, CodingKey { case text, fr, tense, ja }

    public init(text: String, tense: String? = nil, ja: String? = nil) {
        self.text = text; self.tense = tense; self.ja = ja
    }

    public init(from decoder: Decoder) throws {
        // 単なる文字列
        if let single = try? decoder.singleValueContainer(),
           let s = try? single.decode(String.self) {
            self.init(text: s)
            return
        }
        // オブジェクト
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let t = try c.decodeIfPresent(String.self, forKey: .text) {
            self.init(text: t,
                      tense: try c.decodeIfPresent(String.self, forKey: .tense),
                      ja:    try c.decodeIfPresent(String.self, forKey: .ja))
        } else {
            // text が無ければ fr を見る
            let fr = try c.decode(String.self, forKey: .fr)
            self.init(text: fr,
                      tense: try c.decodeIfPresent(String.self, forKey: .tense),
                      ja:    try c.decodeIfPresent(String.self, forKey: .ja))
        }
    }

    public func encode(to encoder: Encoder) throws {
        // 標準化して "text"/"tense"/"ja" で書き出す
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(text, forKey: .text)
        try c.encodeIfPresent(tense, forKey: .tense)
        try c.encodeIfPresent(ja, forKey: .ja)
    }
}

// 関連語: 文字列 or { "term": "...", "pos": "...", "ja": "...", "label": "派生" }
public struct VocabRelated: Codable, Hashable {
    public let label: String?
    public let term: String
    public let pos: String?
    public let ja: String?

    private enum CodingKeys: String, CodingKey { case label, term, pos, ja }

    public init(label: String? = nil, term: String, pos: String? = nil, ja: String? = nil) {
        self.label = label; self.term = term; self.pos = pos; self.ja = ja
    }

    public init(from decoder: Decoder) throws {
        // 素の文字列
        if let single = try? decoder.singleValueContainer(),
           let s = try? single.decode(String.self) {
            self.init(term: s)
            return
        }
        // オブジェクト
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(label: try c.decodeIfPresent(String.self, forKey: .label),
                  term:  try c.decode(String.self, forKey: .term),
                  pos:   try c.decodeIfPresent(String.self, forKey: .pos),
                  ja:    try c.decodeIfPresent(String.self, forKey: .ja))
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(label, forKey: .label)
        try c.encode(term, forKey: .term)
        try c.encodeIfPresent(pos, forKey: .pos)
        try c.encodeIfPresent(ja, forKey: .ja)
    }
}

// 語義: 文字列 or { "glossJa": "..." } / { "ja": "..." } / { "gloss": "..." }
public struct VocabSense: Codable, Hashable {
    public let glossJa: String

    private enum CodingKeys: String, CodingKey { case glossJa, ja, gloss }

    public init(glossJa: String) { self.glossJa = glossJa }

    public init(from decoder: Decoder) throws {
        // 素の文字列
        if let single = try? decoder.singleValueContainer(),
           let s = try? single.decode(String.self) {
            self.init(glossJa: s)
            return
        }
        // オブジェクト
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let g = try c.decodeIfPresent(String.self, forKey: .glossJa) {
            self.init(glossJa: g)
        } else if let g = try c.decodeIfPresent(String.self, forKey: .ja) {
            self.init(glossJa: g)
        } else {
            let g = try c.decode(String.self, forKey: .gloss)
            self.init(glossJa: g)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(glossJa, forKey: .glossJa) // 統一して glossJa で出力
    }
}

public struct VocabWord: Codable, Identifiable, Hashable {
    public let id: String
    public let term: String
    public let meaningJa: String?
    public let pos: String?
    /// 旧スキーマ互換（単体例文）。ある場合は examples にも反映。
    public let example: String?

    public let senses: [VocabSense]?
    public let examples: [VocabExample]?
    public let related: [VocabRelated]?

    public let ipa: String?
    public let gender: String?
    public let plural: String?
    public let cefr: String?
    public let freqRank: Int?
    public let topics: [String]?
    public let audioUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, term, meaningJa, pos, example, senses, examples, related,
             ipa, gender, plural, cefr, freqRank, topics, audioUrl
    }

    public init(
        id: String,
        term: String,
        meaningJa: String?,
        pos: String?,
        example: String? = nil,
        senses: [VocabSense]? = nil,
        examples: [VocabExample]? = nil,
        related: [VocabRelated]? = nil,
        ipa: String? = nil,
        gender: String? = nil,
        plural: String? = nil,
        cefr: String? = nil,
        freqRank: Int? = nil,
        topics: [String]? = nil,
        audioUrl: String? = nil
    ) {
        self.id = id
        self.term = term
        self.meaningJa = meaningJa
        self.pos = pos
        self.example = example
        self.senses = senses
        self.examples = examples
        self.related = related
        self.ipa = ipa
        self.gender = gender
        self.plural = plural
        self.cefr = cefr
        self.freqRank = freqRank
        self.topics = topics
        self.audioUrl = audioUrl
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(String.self, forKey: .id)
        term       = try c.decode(String.self, forKey: .term)
        meaningJa  = try c.decodeIfPresent(String.self, forKey: .meaningJa)
        pos        = try c.decodeIfPresent(String.self, forKey: .pos)
        example    = try c.decodeIfPresent(String.self, forKey: .example)
        senses     = try c.decodeIfPresent([VocabSense].self, forKey: .senses)
        related    = try c.decodeIfPresent([VocabRelated].self, forKey: .related)
        ipa        = try c.decodeIfPresent(String.self, forKey: .ipa)
        gender     = try c.decodeIfPresent(String.self, forKey: .gender)
        plural     = try c.decodeIfPresent(String.self, forKey: .plural)
        cefr       = try c.decodeIfPresent(String.self, forKey: .cefr)
        freqRank   = try c.decodeIfPresent(Int.self, forKey: .freqRank)
        topics     = try c.decodeIfPresent([String].self, forKey: .topics)
        audioUrl   = try c.decodeIfPresent(String.self, forKey: .audioUrl)

        // 柔軟デコード（VocabExample 側がゆるい）
        let decodedExamples = try c.decodeIfPresent([VocabExample].self, forKey: .examples)

        // 旧 example → examples に補完
        if let exArr = decodedExamples, !exArr.isEmpty {
            examples = exArr
        } else if let ex = example, !ex.isEmpty {
            examples = [VocabExample(text: ex)]
        } else {
            examples = nil
        }
    }

    // Encodable はデフォルト合成でOK（現行のフィールド名で出力されます）
}

public extension VocabWord {
    var glossJaResolved: String {
        meaningJa ?? senses?.first?.glossJa ?? "（訳なし）"
    }
    var primaryExampleFr: String? { examples?.first?.text ?? example }
    var primaryExampleJa: String? { examples?.first?.ja }
}

