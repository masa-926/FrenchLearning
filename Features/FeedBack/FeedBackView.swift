// Features/FeedBackView.swift（例）
import SwiftUI

struct FeedBackView: View {
    @State private var message: String = ""
    @ObservedObject private var net = NetworkMonitor.shared

    var body: some View {
        List {
            inputSection
            sendButtonSection
        }
        .navigationTitle("フィードバック")
    }

    private var inputSection: some View {
        Section("内容") {
            TextEditor(text: $message)
                .frame(minHeight: 160)
        }
    }

    private var sendButtonSection: some View {
        Section {
            Button {
                // 送信処理
            } label: {
                Label("送信", systemImage: "paperplane")
            }
            .disabled(!net.isOnline || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

