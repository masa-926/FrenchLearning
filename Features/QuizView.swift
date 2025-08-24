//
//  QuizView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import SwiftUI

struct QuizView: View {
    @StateObject var vm = QuizViewModel()

    var body: some View {
        VStack(spacing: 20) {
            if vm.finished {
                VStack(spacing: 12) {
                    Text("結果").font(.largeTitle.bold())
                    Text("\(vm.score) / \(vm.totalQuestions)").font(.title)

                    // 弱点復習ボタン（間違いが1つ以上のとき）
                    if !vm.wrongWordIDs.isEmpty {
                        Button {
                            vm.restartWeakMode()
                        } label: {
                            Label("弱点を復習（\(vm.wrongWordIDs.count)語）", systemImage: "arrow.clockwise.circle")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Button("もう一度（全体から出題）") {
                        vm.allWords.shuffle()
                        vm.loadAndStart()
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()

            } else if let q = vm.current {
                // 進捗
                Text("Q\(vm.questionIndex) / \(vm.totalQuestions)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 問題文（日本語の意味）
                Text(q.promptJa)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)

                // 選択肢（フランス語）
                VStack(spacing: 12) {
                    ForEach(q.optionsFr, id: \.self) { opt in
                        Button {
                            vm.select(option: opt)
                        } label: {
                            HStack {
                                Text(opt).frame(maxWidth: .infinity, alignment: .leading)
                                if vm.selected != nil {
                                    if opt == q.correctTermFr {
                                        Image(systemName: "checkmark.circle.fill")
                                    } else if opt == vm.selected {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                }
                            }
                            .padding()
                            .background(buttonBackground(opt: opt, q: q))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.selected != nil) // 回答後は選択不可
                    }
                }

                // 次へ
                Button(vm.selected == nil ? "答えを選んでください" : "次へ") {
                    vm.nextQuestion()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.selected == nil)

                Spacer()

            } else {
                Text("出題できる単語が足りません（4語以上必要）")
                Spacer()
            }
        }
        .padding()
        .navigationTitle("クイズ（4択）")
    }

    // 選択肢の背景色（回答後：正解=緑, 不正解=赤, それ以外=標準）
    @ViewBuilder
    private func buttonBackground(opt: String, q: QuizQuestion) -> some View {
        if let sel = vm.selected {
            if opt == q.correctTermFr {
                Color.green.opacity(0.2)
            } else if opt == sel {
                Color.red.opacity(0.2)
            } else {
                Color.gray.opacity(0.08)
            }
        } else {
            Color.gray.opacity(0.08)
        }
    }
}
