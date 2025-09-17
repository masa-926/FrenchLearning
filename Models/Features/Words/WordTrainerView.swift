import SwiftUI

struct WordTrainerView: View {
    @StateObject var vm: WordTrainerViewModel

    private let initialOrder: TrainerOrder?
    private let initialPlan: TodayPlan?

    // 既存 init
    init(vm: WordTrainerViewModel = WordTrainerViewModel()) {
        _vm = StateObject(wrappedValue: vm)
        self.initialOrder = nil
        self.initialPlan  = nil
    }

    // 互換 init
    init(packFilename: String?, initialOrder: TrainerOrder? = nil, initialPlan: TodayPlan? = nil) {
        if let file = packFilename, !file.isEmpty {
            _vm = StateObject(wrappedValue: WordTrainerViewModel(packFilename: file, initialPlan: initialPlan))
        } else {
            _vm = StateObject(wrappedValue: WordTrainerViewModel(initialPlan: initialPlan))
        }
        self.initialOrder = initialOrder
        self.initialPlan  = initialPlan
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            if let w = vm.current {
                WordCard(word: w, showMeaning: vm.showMeaning)

                ActionBar(
                    isRevealed: vm.showMeaning,
                    onReveal: { vm.reveal() },
                    onCorrect: { vm.review(correct: true) },
                    onWrong: { vm.review(correct: false) },
                    onSkipNonSRS: { vm.nextNonSRS() }
                )
            } else {
                EmptyState(
                    onRestartSameOrder: { vm.restart(shuffled: false) },
                    onRestartShuffle:   { vm.restart(shuffled: true) },
                    onRandomPick:       { vm.pickRandomIgnoringSRS() }
                )
            }
        }
        .padding()
        .navigationTitle("トレーナー")
        .onAppear {
            if let ord = initialOrder { vm.updateOrder(ord.rawValue) }
            _ = initialPlan // 受け口のみ維持
            vm.alignToSRSIfNeeded()
        }
        // ← SearchView からのジャンプ通知はここで受ける（vm にアクセス可）
        .onReceive(NotificationCenter.default.publisher(for: .searchJumpRequested)) { note in
            if let term = (note.userInfo?["term"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !term.isEmpty {
                vm.jump(toTerm: term)
            }
        }
    }
   


    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text(progressText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                vm.nextDue()
            } label: {
                Label("次の復習へ", systemImage: "arrow.turn.down.right")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
        }
    }

    private var progressText: String {
        let total = max(vm.words.count, 0)
        let current = (vm.current != nil) ? (vm.index + 1) : 0
        return "進捗 \(current)/\(total)"
    }
}

// MARK: - WordCard

private struct WordCard: View {
    let word: VocabWord
    let showMeaning: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(word.term)
                    .font(.system(size: 36, weight: .bold))
                Spacer()
                Button {
                    Pronouncer.shared.speak(word.term)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .imageScale(.large)
                        .accessibilityLabel("発音を再生")
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showMeaning {
                if let pos = word.pos, !pos.isEmpty {
                    Text(pos).font(.subheadline).foregroundStyle(.secondary)
                }
                Text(word.meaningJa ?? "")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let ex = word.example, !ex.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text(ex).frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("意味を表示して答えましょう")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.quaternary, lineWidth: 1))
    }
}

// MARK: - ActionBar

private struct ActionBar: View {
    let isRevealed: Bool
    let onReveal: () -> Void
    let onCorrect: () -> Void
    let onWrong: () -> Void
    let onSkipNonSRS: () -> Void

    var body: some View {
        if !isRevealed {
            Button(action: onReveal) {
                Label("意味を表示", systemImage: "eye")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .simultaneousGesture(TapGesture().onEnded {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            })
        } else {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Button(role: .destructive, action: onWrong) {
                        Label("不正解", systemImage: "xmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onCorrect) {
                        Label("正解", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button(action: onSkipNonSRS) {
                    Label("次へ（非SRS）", systemImage: "chevron.right").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - EmptyState

private struct EmptyState: View {
    let onRestartSameOrder: () -> Void
    let onRestartShuffle: () -> Void
    let onRandomPick: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal").font(.system(size: 44, weight: .semibold))
            Text("本日の出題はありません").font(.headline)
            Text("設定やユニットを変えるか、再学習を始めましょう。")
                .font(.footnote).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("再開（同順）", action: onRestartSameOrder).buttonStyle(.bordered)
                Button("再開（シャッフル）", action: onRestartShuffle).buttonStyle(.bordered)
            }
            Button("ランダムで1語へ", action: onRandomPick)
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 24)
    }
}
