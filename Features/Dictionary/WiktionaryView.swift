import SwiftUI

struct WiktionaryView: View {
    let headword: String
    @ObservedObject private var net = NetworkMonitor.shared

    @State private var isLoading = true
    @State private var progress: Double = 0

    private var pageURL: URL {
        let encoded = headword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? headword
        return URL(string: "https://fr.wiktionary.org/wiki/\(encoded)")!
    }

    var body: some View {
        VStack(spacing: 0) {
            if !net.isOnline {
                offlineView
            } else {
                ZStack(alignment: .top) {
                    WebView(url: pageURL, progress: $progress, isLoading: $isLoading)
                        .edgesIgnoringSafeArea(.bottom)

                    if isLoading {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .padding(.top, 0)
                    }
                }
            }
        }
        .navigationTitle(headword)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // 同じ URL を指定し直して再読込
                    isLoading = true
                    progress = 0
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(!net.isOnline)
            }
        }
    }

    private var offlineView: some View {
        VStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle)
            Text("オフラインです")
            Text("ネットワークに接続するとWiktionaryを読み込みます。")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

