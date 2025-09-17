// Features/Quiz/QuizView.swift
import SwiftUI
import UIKit

struct QuizView: View {
    @StateObject private var vm: QuizViewModel
    @State private var bounce = false

    init(vm: QuizViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        VStack(spacing: 20) {
            if vm.finished {
                // 結果画面
                VStack(spacing: 12) {
                    Text("結果")
                        .font(.largeTitle.bold())
                    Text("\(vm.score) / \(vm.totalQuestions)")
                        .font(.title)

                    // 弱点復習へ
                    if !vm.wrongWordIDs.isEmpty {
                        NavigationLink {
                            WordTrainerView(
                                packFilename: vm.scopePackFilename,
                                initialOrder: TrainerOrder.weak
                            )
                        } label: {
                            Label("弱点を復習（\(vm.wrongWordIDs.count)語）", systemImage: "arrow.clockwise.circle")
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            MistakeBuffer.shared.seed(vm.wrongWordIDs)
                        })
                        .buttonStyle(.borderedProminent)
                    }

                    // もう一度
                    Button("全体からもう一度") {
                        vm.allWords.shuffle()
                        vm.generate(questionCount: 10)
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()

            } else if let q = vm.current {
                // 進捗
                Text("Q\(vm.idx + 1) / \(vm.totalQuestions)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 問題文（日本語）
                Text(q.promptJa)
                    .font(.title2)
                    .scaleEffect(bounce ? 1.06 : 1.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.7), value: bounce)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)

                // 選択肢（フランス語）
                VStack(spacing: 12) {
                    ForEach(q.optionsFr, id: \.self) { opt in
                        Button {
                            vm.select(option: opt)

                            // 軽いハプティクスと“ポンッ”と弾む演出
                            let gen = UINotificationFeedbackGenerator()
                            if opt == q.correctTermFr {
                                gen.notificationOccurred(.success)
                                bounce.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    bounce.toggle()
                                }
                            } else {
                                gen.notificationOccurred(.error)
                            }
                        } label: {
                            HStack {
                                Text(opt)
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        .disabled(vm.selected != nil)
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
                // プール不足
                Text("出題できる単語が足りません（4語以上必要）")
                Spacer()
            }
        }
        .padding()
        .navigationTitle("クイズ（4択）")
    }

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

