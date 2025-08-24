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

                NavigationLink("文章添削") { ProofreadView() }
                    .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    NavigationLink { SettingsView() } label: {  // ← ここがポイント
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationTitle("FrenchLearning")
        }
    }
}

#Preview { ContentView() }
