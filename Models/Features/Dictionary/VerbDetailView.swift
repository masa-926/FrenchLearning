// Features/WordDetail/VerbDetailView.swift
import SwiftUI

struct VerbDetailView: View {
    let word: VocabWord
    @State private var tab: Int
    private let conj = LefffConjugator.shared

    @State private var reflexive = false
    @State private var negative  = false

    init(word: VocabWord, initialTab: Int? = nil) {
        self.word = word
        _tab = State(initialValue: initialTab ?? 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // セグメント
            Picker("", selection: $tab) {
                Text("意味").tag(0)
                Text("活用").tag(1)
                Text("用法").tag(2)
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            // TabView は型推論が重くなりやすいので switch 切替
            Group {
                switch tab {
                case 0:
                    BasicDetailTab(word: word)
                case 1:
                    ConjugationTab(
                        word: word,
                        reflexive: $reflexive,
                        negative: $negative,
                        groups: groupedConjugations()
                    )
                default:
                    UsageTab(word: word)
                }
            }
        }
        .navigationTitle(word.term)
    }

    // MARK: - データ前処理

    struct ConjGroup: Identifiable, Hashable {
        var id: String { mood }
        let mood: String
        let rows: [VerbConjugation]
    }

    private let moodOrder: [String] = [
        "indicatif", "subjonctif", "conditionnel", "impératif", "participe", "infinitif"
    ]
    private let tenseOrder: [String] = [
        "présent","imparfait","passé simple","futur",
        "passé composé","plus-que-parfait","futur antérieur"
    ]

    private func groupedConjugations() -> [ConjGroup] {
        let cs = conj.conjugations(for: word.term)
        let groups = Dictionary(grouping: cs, by: { $0.mood.lowercased() })
        let sortedMoods = groups.keys.sorted {
            (moodOrder.firstIndex(of: $0) ?? Int.max) < (moodOrder.firstIndex(of: $1) ?? Int.max)
        }
        return sortedMoods.map { m in
            let rows = (groups[m] ?? []).sorted {
                (tenseOrder.firstIndex(of: $0.tense.lowercased()) ?? Int.max) <
                (tenseOrder.firstIndex(of: $1.tense.lowercased()) ?? Int.max)
            }
            return ConjGroup(mood: m.capitalized, rows: rows)
        }
    }
}

// MARK: - Tab 0: 意味
private struct BasicDetailTab: View {
    let word: VocabWord
    var body: some View {
        WordBasicDetailView(word: word)
    }
}

// MARK: - Tab 1: 活用
private struct ConjugationTab: View {
    let word: VocabWord
    @Binding var reflexive: Bool
    @Binding var negative: Bool
    let groups: [VerbDetailView.ConjGroup]

    var body: some View {
        List {
            Section {
                Toggle("再帰（se）", isOn: $reflexive)
                Toggle("否定（ne … pas）", isOn: $negative)
                Text("※ 命令法は簡易表示（トグル適用外）")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Section("\(word.term) の活用") {
                ForEach(groups) { group in
                    Section(group.mood) {
                        ForEach(group.rows, id: \.tense) { row in
                            ConjugationRowView(
                                mood: group.mood,
                                row: row,
                                reflexive: reflexive,
                                negative: negative
                            )
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }
}

private struct ConjugationRowView: View {
    let mood: String
    let row: VerbConjugation
    let reflexive: Bool
    let negative: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(row.tense.capitalized).font(.headline)

            // forms: [person: form] — 安定順で表示
            let order = ["je","j'","tu","il","elle","il/elle","nous","vous","ils","elles","ils/elles"]
            let sortedForms = row.forms
                .map { (person: $0.key, base: $0.value) }
                .sorted {
                    (order.firstIndex(of: $0.person.lowercased()) ?? Int.max) <
                    (order.firstIndex(of: $1.person.lowercased()) ?? Int.max)
                }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(sortedForms, id: \.person) { entry in
                    Text(formString(person: entry.person, base: entry.base))
                }
            }
        }
    }

    private func formString(person: String, base: String) -> String {
        let isImperative = mood.lowercased().contains("impératif")
        if isImperative {
            return "\(person): \(base)"
        } else {
            let shown = ConjugationSurface.indicativeLike(
                person: person, base: base, reflexive: reflexive, negative: negative
            )
            return "\(person): \(shown)"
        }
    }
}

// MARK: - Tab 2: 用法
private struct UsageTab: View {
    let word: VocabWord

    var body: some View {
        // 先に並べ替えを済ませ、List ビルドを軽くする
        let pats = UDPatternStore.shared.patterns(for: word.term)
        let sorted = pats.sorted { $0.count > $1.count }

        return List {
            if !sorted.isEmpty {
                Section("前置詞パターン（頻度順）") {
                    ForEach(sorted) { p in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(word.term) + \(p.preposition.isEmpty ? "—" : p.preposition)")
                                    .font(.headline)
                                Spacer()
                                Text("×\(p.count)").font(.caption).foregroundStyle(.secondary)
                            }
                            Text(p.complement).font(.caption).foregroundStyle(.secondary)
                            Text("例: \(p.example)").font(.body)
                            if let src = p.source, !src.isEmpty {
                                Text("出典: \(src)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("再帰（se ～）") {
                Text("再帰形の例や注意点（データ拡充予定）").font(.caption)
            }

            WiktionarySection(term: word.term)
        }
    }
}

