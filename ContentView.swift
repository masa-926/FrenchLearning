//
//  ContentView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                NavigationLink("単語学習") { WordTrainerView() }
                    .buttonStyle(.borderedProminent)

                NavigationLink("クイズ（後で）") { Text("次フェーズ") }
                    .buttonStyle(.bordered)

                NavigationLink("文章添削（モック）") { ProofreadView() } // ← 次で作る画面
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
                    NavigationLink { SettingsView() } label: {  // ← ここを設定画面に
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationTitle("FrenchLearning")
        }
    }
}

#Preview { ContentView() }
