//
//  Features: Home: HomeView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

// Features/Home/HomeView.swift
import SwiftUI

struct HomeView: View {
var body: some View {
NavigationStack {
VStack(spacing: 20) {
NavigationLink("単語学習") { WordTrainerView() }
.buttonStyle(.borderedProminent)

NavigationLink("クイズ（後で）") { Text("次フェーズ") }
.buttonStyle(.bordered)

NavigationLink("文章添削（モック）") { Text("後で有効化") }
.buttonStyle(.bordered)

Spacer()
}
.padding()
.toolbar {
ToolbarItem(placement: .topBarTrailing) {
Link(destination: URL(string:"https://example.com/feedback")!) {
Image(systemName: "bubble.left.and.bubble.right")
}
}
ToolbarItem(placement: .bottomBar) {
NavigationLink { Text("設定（APIキー・進捗リセット）") } label: {
Image(systemName: "gearshape")
}
}
}
.navigationTitle("FrenchLearning")
}
}
}
