
import SwiftUI

struct ProofreadView: View {
    @StateObject var vm = ProofreadViewModel()
    @AppStorage("openai.dailyLimit") private var dailyLimit: Int = 20
    @EnvironmentObject private var net: NetworkMonitor       // ← 追加

    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $vm.input)
                .frame(minHeight: 160)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
                .padding(.top, 8)

            Button {
                Task { await vm.send() }
            } label: {
                if vm.isLoading { ProgressView() } else { Text("AIに添削してもらう") }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading || !net.isConnected)      // ← オフライン時は自動で無効化

            Text("本日の残り: \(DailyQuotaStore.shared.remaining(limit: dailyLimit)) 回")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let r = vm.result {
                let (origHL, corrHL) = DiffHighlighter.highlight(original: vm.input, corrected: r.corrected)
                VStack(alignment: .leading, spacing: 10) {
                    Text("元の文").font(.headline)
                    Text(origHL)
                    Text("修正文").font(.headline).padding(.top, 6)
                    Text(corrHL)
                    Divider().padding(.vertical, 6)
                    Text("ポイント").font(.headline)
                    ForEach(r.explanations, id: \.self) { exp in
                        Text("• \(exp)").frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let err = vm.error { Text(err).foregroundColor(.red) }
            Spacer()
        }
        .padding()
        .navigationTitle("文章添削")
        // 画面最上部にバナーを重ねる
        .overlay(alignment: .top) {
            OfflineBanner(isConnected: net.isConnected)
        }
    }
}
