// Features/Dev/JSONValidatorView.swift
import SwiftUI
import Foundation

private struct JSONFileReport: Identifiable, Hashable {
    let id = UUID()
    let filename: String
    let decodeOK: Bool
    let wordCount: Int
    let errors: [String]
    let warnings: [String]
}

struct JSONValidatorView: View {
    @State private var reports: [JSONFileReport] = []
    @State private var isScanning = false

    var body: some View {
        List {
            Section {
                Button {
                    Task { await scan() }
                } label: {
                    if isScanning {
                        ProgressView().padding(.vertical, 6)
                    } else {
                        Label("JSONをスキャン", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanning)
            }

            if reports.isEmpty {
                Section {
                    Text("まだ結果がありません。「JSONをスキャン」を押してください。")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("スキャン結果") {
                    ForEach(reports) { r in
                        NavigationLink {
                            JSONReportDetailView(report: r)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: r.decodeOK ? "checkmark.seal.fill" : "xmark.octagon.fill")
                                    .foregroundStyle(r.decodeOK ? .green : .red)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(r.filename).font(.headline)
                                    if r.decodeOK {
                                        Text("語彙 \(r.wordCount) 件 • 警告 \(r.warnings.count) 件")
                                            .font(.caption).foregroundStyle(.secondary)
                                    } else {
                                        Text("デコード失敗（詳細を表示）")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("JSON検証")
        .task { await scan() }
    }

    // MARK: - Scan

    private func listWordsetJSONs() -> [String] {
        let all = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        return all
            .map { ($0 as NSString).lastPathComponent }
            .filter { $0.lowercased().hasPrefix("wordset_") }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private func scanOne(filename: String) -> JSONFileReport {
        // まず既存のローダで
        let words = VocabLoader.shared.load(fileNamed: filename)
        if !words.isEmpty {
            return JSONFileReport(
                filename: filename,
                decodeOK: true,
                wordCount: words.count,
                errors: [],
                warnings: warnings(for: words, filename: filename)
            )
        }

        // 詳細エラー取得のために直接デコード
        let all = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        if let path = all.first(where: { ($0 as NSString).lastPathComponent == filename }) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoded = try JSONDecoder().decode([VocabWord].self, from: data)
                return JSONFileReport(
                    filename: filename,
                    decodeOK: true,
                    wordCount: decoded.count,
                    errors: [],
                    warnings: warnings(for: decoded, filename: filename)
                )
            } catch {
                return JSONFileReport(
                    filename: filename,
                    decodeOK: false,
                    wordCount: 0,
                    errors: [String(describing: error)],
                    warnings: []
                )
            }
        } else {
            return JSONFileReport(
                filename: filename,
                decodeOK: false,
                wordCount: 0,
                errors: ["バンドル内に見つかりませんでした"],
                warnings: []
            )
        }
    }

    private func scanSync() -> [JSONFileReport] {
        listWordsetJSONs().map { scanOne(filename: $0) }
    }

    private func scanAsync() async -> [JSONFileReport] {
        // 今は軽量なので同期でOK。将来重くなれば並列化。
        return scanSync()
    }

    private func scan() async {
        isScanning = true
        defer { isScanning = false }
        reports = await scanAsync()
    }
}

// MARK: - ヘルパー（グローバル関数に統一）

// Unitファイルかどうか（"wordset_*_uNN.json" 想定）
private func isUnitFile(_ name: String) -> Bool {
    // 簡易判定（u0x / u1x の2桁にも反応）
    let lower = name.lowercased()
    return lower.contains("_u0") || lower.contains("_u1")
}

// 旧来の基本チェック（訳/例文/関連語）
private func baseWarnings(for words: [VocabWord]) -> [String] {
    var warns: [String] = []
    for w in words {
        // 訳（meaningJa or senses[0].glossJa）が無い
        let gloss = (w.meaningJa ?? "").isEmpty
            ? (w.senses?.first?.glossJa ?? "")
            : (w.meaningJa ?? "")
        if gloss.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            warns.append("訳なし: id=\(w.id) term=\(w.term)")
        }

        // 例文が 2 個未満
        let exCount = w.examples?.count ?? 0
        if exCount < 2 {
            warns.append("例文が少ない(\(exCount)) : id=\(w.id) term=\(w.term)")
        }

        // 関連語に意味（ja）が無い項目がある
        if let rel = w.related {
            for r in rel where (r.ja ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                warns.append("関連語に訳なし: \(w.term) → \(r.term) [\(r.label ?? "—")]")
            }
        }
    }
    return warns
}

// 追加の品質チェック（ユニット50語 / 名詞gender / 例文ちょうど2個）
private func warnings(for words: [VocabWord], filename: String) -> [String] {
    var warns = baseWarnings(for: words)

    if isUnitFile(filename) && words.count != 50 {
        warns.append("ユニット語数が \(words.count) 件（期待値 50）")
    }
    for w in words {
        if (w.pos ?? "").contains("n.") && (w.gender ?? "").isEmpty {
            warns.append("名詞なのに gender 無し: \(w.term)")
        }
        if (w.examples?.count ?? 0) != 2 {
            warns.append("例文が2つではない: \(w.term) (\(w.examples?.count ?? 0)個)")
        }
    }
    return warns
}

// MARK: - Detail

private struct JSONReportDetailView: View {
    let report: JSONFileReport

    var body: some View {
        List {
            Section("ファイル") {
                LabeledContent("名前", value: report.filename)
                LabeledContent("デコード", value: report.decodeOK ? "成功" : "失敗")
                if report.decodeOK {
                    LabeledContent("件数", value: "\(report.wordCount)")
                }
            }

            if !report.errors.isEmpty {
                Section("エラー") {
                    ForEach(report.errors, id: \.self) { e in
                        Text(e).foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }
            }

            if !report.warnings.isEmpty {
                Section("警告（品質チェック）") {
                    ForEach(report.warnings, id: \.self) { w in
                        Text("• \(w)").textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle("詳細")
    }
}

#Preview {
    NavigationStack {
        JSONValidatorView()
    }
}

