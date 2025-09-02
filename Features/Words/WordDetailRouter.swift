//
//  WordDetajlRouter .swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/31.
//

import SwiftUI

/// 検索結果から語詳細へ遷移するためのハブ
struct WordDetailRouter: View {
    let wordID: String
    let initialTab: Int?

    init(wordID: String, initialTab: Int? = nil) {
        self.wordID = wordID
        self.initialTab = initialTab
    }

    private var word: VocabWord? {
        VocabLoader.shared.loadAll().first(where: { $0.id == wordID })
    }

    var body: some View {
        if let w = word {
            if (w.pos ?? "").contains("v.") {
                VerbDetailView(word: w, initialTab: initialTab)
            } else {
                WordBasicDetailView(word: w)
            }
        } else {
            Text("語が見つかりません")
        }
    }
}

struct WordBasicDetailView: View {
    let word: VocabWord
    var body: some View {
        List {
            Section("見出し") { Text(word.term).font(.title2.bold()) }
            Section("意味") { Text(word.glossJaResolved) }
            if let exs = word.examples, !exs.isEmpty {
                Section("例文") {
                    ForEach(exs, id: \.self) { ex in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.text)
                            if let ja = ex.ja { Text(ja).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            WiktionarySection(term: word.term) // 3) オンライン辞書
        }
        .navigationTitle("単語詳細")
    }
}

