// Features/Proofread/ProofreadView.swift
import SwiftUI
import UIKit

struct ProofreadView: View {
    @StateObject private var vm = ProofreadViewModel()
    @AppStorage("openai.dailyLimit") private var dailyLimit: Int = 20
    @ObservedObject private var net = NetworkMonitor.shared

    // 残回数（描画毎に再計算）
    private var remaining: Int { QuotaStore.shared.remaining(limit: dailyLimit) }

    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $vm.input)
                .frame(minHeight: 160)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
                .padding(.top, 8)

            Button {
                Task {
                    await vm.send(preferMock: !net.isOnline)
                    // 成功時だけクォータ消費
                    if vm.result != nil {
                        _ = QuotaStore.shared.increment()
                    }
                }
            } label: {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Label("AIに添削してもらう", systemImage: "wand.and.stars")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading || !net.isOnline || remaining == 0)

            HStack(spacing: 8) {
                Text("本日の残り: \(remaining) 回")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if remaining == 0 {
                    Text("（上限に達しました）")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let r = vm.result {
                VStack(alignment: .leading, spacing: 10) {
                    Text("元の文").font(.headline)
                    Text(vm.input.isEmpty ? "（入力が空です）" : vm.input)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("修正文").font(.headline).padding(.top, 6)
                    Text(r.corrected)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Button {
                            UIPasteboard.general.string = r.corrected
                        } label: {
                            Label("コピー", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)

                        ShareLink(item: r.corrected) {
                            Label("共有", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.bottom, 4)

                    if !r.explanations.isEmpty {
                        Divider().padding(.vertical, 6)
                        Text("ポイント").font(.headline)
                        ForEach(r.explanations, id: \.self) { exp in
                            Text("• \(exp)").frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let err = vm.error {
                Text(err).foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("文章添削")
        .overlay(alignment: .top) { OfflineBanner(isOnline: net.isOnline) }
    }
}

