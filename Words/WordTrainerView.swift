//
//  WordTrainerView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

// Features/Words/WordTrainerView.swift
import SwiftUI

struct WordTrainerView: View {
@StateObject var vm = WordTrainerViewModel()

var body: some View {
VStack(spacing: 24) {
if let w = vm.current {
Text(w.term)
.font(.system(size: 40, weight: .bold))
.padding(.top, 32)

if vm.showMeaning {
VStack(spacing: 8) {
Text(w.meaningJa).font(.title2)
if let ex = w.example, !ex.isEmpty {
Text(ex).font(.body).foregroundStyle(.secondary)
}
}
.transition(.opacity)
} else {
Button("意味を表示") { vm.reveal() }
.buttonStyle(.borderedProminent)
}

Button("次へ") { vm.next() }
.buttonStyle(.bordered)
.padding(.top, 8)

Spacer()
} else {
Text("単語データが読み込めませんでした。")
}
}
.padding()
.navigationTitle("単語学習")
}
}
