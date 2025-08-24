//
//  Common:OfflineBanner.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import SwiftUI

struct OfflineBanner: View {
    let isConnected: Bool

    var body: some View {
        if !isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("オフラインです。ネット接続を確認してください。")
                    .font(.footnote)
                Spacer()
            }
            .padding(10)
            .background(Color.yellow.opacity(0.95))
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
