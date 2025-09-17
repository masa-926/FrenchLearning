//
//  GlobalSearchView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/30.
//

import SwiftUI

struct GlobalSearchView: View {
    @State private var q = ""
    @State private var results: [VocabWord] = []

    var body: some View {
        List {
            Section {
                TextField("単語/訳/関連語で検索", text: $q)
                    .textInputAutocapitalization(.never)
                    .onSubmit { search() }
                Button("検索") { search() }.buttonStyle(.bordered)
            }
            Section("結果 \(results.count) 件") {
                ForEach(results, id: \.id) { w in
                    VStack(alignment: .leading) {
                        Text(w.term).font(.headline)
                        Text(w.glossJaResolved).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("検索")
    }

    private func search() {
        let all = VocabLoader.shared.loadAll()
        let k = q.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { results = []; return }
        results = all.filter { w in
            if w.term.lowercased().contains(k) { return true }
            if w.glossJaResolved.lowercased().contains(k) { return true }
            if let rel = w.related, rel.contains(where: { $0.term.lowercased().contains(k) || ($0.ja ?? "").lowercased().contains(k) }) { return true }
            return false
        }
    }
}
