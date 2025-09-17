import SwiftUI

/// 単語詳細画面などから差し込む“Wiktionary へ”の導線
struct WiktionarySection: View {
    let term: String

    var body: some View {
        Section("辞書") {
            NavigationLink(
                destination: WiktionaryView(headword: term)
            ) {
                Label("Wiktionary で開く", systemImage: "book.circle")
            }
        }
    }
}

