import SwiftUI
import Foundation

struct WordUnitIntroView: View {
    let packFilename: String
    @State private var preview: [VocabWord] = []

    var body: some View {
        List {
            Section("ユニットの概要") {
                Text(fileTitle)
                    .font(.headline)
                Text("収録語数（読み込み済み）: \(preview.count) 語")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("プレビュー（先頭10語）") {
                if preview.isEmpty {
                    Text("このユニットの単語が見つかりません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(preview.prefix(10)), id: \.id) { w in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(w.term).font(.headline)
                            Text(w.meaningJa ?? "")   // ← ここだけ修正
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Section {
                NavigationLink(
                    destination: WordTrainerView(packFilename: packFilename)
                ) {
                    Label("このユニットで学習を開始", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(fileTitle)
        .onAppear {
            preview = VocabLoader.shared.load(fileNamed: packFilename)
        }
    }

    private var fileTitle: String {
        let base = (packFilename as NSString)
            .lastPathComponent
            .replacingOccurrences(of: ".json", with: "")
        if let range = base.range(of: #"wordset_([^_]+)_u(\d+)"#, options: .regularExpression) {
            let s = String(base[range])
            return s
                .replacingOccurrences(of: "wordset_", with: "")
                .replacingOccurrences(of: "_", with: " ")
        }
        return base
    }
}

