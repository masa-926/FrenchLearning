//
//  Features:Proofread:ProofreadView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import SwiftUI

struct ProofreadView: View {
    @StateObject var vm = ProofreadViewModel()

    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $vm.input)
                .frame(minHeight: 160)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
                .padding(.top, 8)

            Button {
                Task { await vm.send() }
            } label: {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text("AIに添削してもらう（モック）")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading)

            if let r = vm.result {
                // 差分ハイライトを生成
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


            if let err = vm.error {
                Text(err).foregroundColor(.red) // foregroundStyle(.red) でもOK
            }

            Spacer()
        }
        .padding()
        .navigationTitle("文章添削")
    }
}
