// Features/Search/SearchView.swift
import SwiftUI
import Foundation

struct SearchView: View {
    @State private var q = ""
    @State private var hits: [SearchHit] = []

    // ファセット
    @State private var posFilter: String = "すべて"
    @State private var cefrFilter: String = "すべて"
    @State private var topicFilter: String = "すべて"
    @State private var highFreqOnly: Bool = false

    private let index: SearchIndex
    private let allPOS: [String]
    private let allCEFR: [String]
    private let allTopics: [String]

    init() {
        // 全ユニット横断でロード
        let all = VocabLoader.shared.loadAll()
        self.index = SearchIndex(words: all)

        let posSet = Set(
            all.compactMap { ($0.pos ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
               .filter { !$0.isEmpty }
        )
        let cefrSet = Set(
            all.compactMap { ($0.cefr ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
               .filter { !$0.isEmpty }
        )
        let topicSet = Set(
            all.flatMap { $0.topics ?? [] }
               .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
               .filter { !$0.isEmpty }
        )

        self.allPOS = ["すべて"] + posSet.sorted()
        self.allCEFR = ["すべて"] + cefrSet.sorted()
        self.allTopics = ["すべて"] + topicSet.sorted()
    }

    var body: some View {
        List {
            // フィルタUI
            Section("絞り込み") {
                HStack {
                    Menu {
                        Picker("品詞", selection: $posFilter) {
                            ForEach(allPOS, id: \.self) { Text($0).tag($0) }
                        }
                    } label: { Label("品詞: \(posFilter)", systemImage: "slider.horizontal.3") }

                    Menu {
                        Picker("CEFR", selection: $cefrFilter) {
                            ForEach(allCEFR, id: \.self) { Text($0).tag($0) }
                        }
                    } label: { Label("CEFR: \(cefrFilter)", systemImage: "character.book.closed") }
                }

                HStack {
                    Menu {
                        Picker("トピック", selection: $topicFilter) {
                            ForEach(allTopics, id: \.self) { Text($0).tag($0) }
                        }
                    } label: { Label("トピック: \(topicFilter)", systemImage: "tag") }

                    Toggle("高頻度のみ", isOn: $highFreqOnly)
                        .toggleStyle(.switch)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // 結果
            Section {
                ForEach(filtered(hits)) { hit in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(hit.title).font(.headline)
                            Spacer()
                            badge(for: hit)
                        }

                        // スニペット強調表示
                        Text(highlight(hit.snippet, query: q))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // クイックアクション
                        HStack(spacing: 8) {
                            if hit.isVerb {
                                NavigationLink {
                                    WordDetailRouter(wordID: hit.id, initialTab: 1) // 活用タブ
                                } label: {
                                    Label("活用", systemImage: "text.book.closed")
                                }
                                .buttonStyle(.bordered)

                                NavigationLink {
                                    WordDetailRouter(wordID: hit.id, initialTab: 2) // 用法タブ
                                } label: {
                                    Label("用法", systemImage: "list.bullet")
                                }
                                .buttonStyle(.bordered)
                            }

                            NavigationLink {
                                WordDetailRouter(wordID: hit.id) // 基本詳細（意味）
                            } label: {
                                Label("詳細", systemImage: "magnifyingglass.circle")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .font(.caption)
                        .padding(.top, 2)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("検索")

        // iOS 17+: 常時表示 / iOS 16: 従来（引き下げで表示）
        #if os(iOS)
        .modifier(_SearchableModifier_iOS(text: $q))
        #else
        .searchable(text: $q, prompt: "単語・意味・例文で検索")
        #endif

        .onChange(of: q) { _, new in
            if new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                hits = []
            } else {
                hits = index.search(new)
            }
        }
    }

    private func filtered(_ arr: [SearchHit]) -> [SearchHit] {
        arr.filter { h in
            let posOK   = (posFilter == "すべて")   || (h.pos ?? "") == posFilter
            let cefrOK  = (cefrFilter == "すべて")  || (h.cefr ?? "") == cefrFilter
            let topicOK = (topicFilter == "すべて") || h.topics.contains(where: { $0 == topicFilter })
            let freqOK  = (!highFreqOnly) || ((h.freqRank ?? Int.max) <= 5000)
            return posOK && cefrOK && topicOK && freqOK
        }
    }

    private func badge(for hit: SearchHit) -> some View {
        HStack(spacing: 6) {
            if hit.kind == .headword { Tag("見出し") }
            if let p = hit.pos, !p.isEmpty { Tag(p) }
            if let c = hit.cefr, !c.isEmpty { Tag(c) }
            if let r = hit.freqRank { Tag("頻度\(r)") }
        }
    }

    @ViewBuilder private func Tag(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().strokeBorder(.secondary.opacity(0.4)))
    }

    /// クエリ一致部分を太字に（大文字小文字/ダイアクリティクスを無視）
    private func highlight(_ text: String, query: String) -> AttributedString {
        var attr = AttributedString(text)
        let tokens = normalize(query).split(separator: " ").map(String.init).filter { $0.count >= 2 }
        guard !tokens.isEmpty else { return attr }

        for tk in tokens {
            var searchRange: Range<String.Index>? = text.startIndex..<text.endIndex
            while let r = text.range(of: tk, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
                if let lower = AttributedString.Index(r.lowerBound, within: attr),
                   let upper = AttributedString.Index(r.upperBound, within: attr) {
                    attr[lower..<upper].inlinePresentationIntent = .stronglyEmphasized
                }
                searchRange = r.upperBound..<text.endIndex
            }
        }
        return attr
    }

    // 拡張は使わず、View 内のヘルパー関数で正規化（重複定義の衝突を回避）
    private func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        // フランス語特化にしたい場合は: Locale(identifier: "fr_FR")
    }
}

// iOS 用：iOS 16/17 で .searchable の挙動を分岐
#if os(iOS)
private struct _SearchableModifier_iOS: ViewModifier {
    @Binding var text: String
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .searchable(
                    text: $text,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "単語・意味・例文で検索"
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        } else {
            content
                .searchable(
                    text: $text,
                    placement: .navigationBarDrawer,
                    prompt: "単語・意味・例文で検索"
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
    }
}
#endif

