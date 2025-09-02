//
//  PercentBadge.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/28.
//

import SwiftUI

struct PercentBadge: View {
    let percent: Int
    var body: some View {
        Text("\(percent)%")
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color.orange.opacity(0.9)))
            .foregroundStyle(.white)
            .accessibilityLabel("進捗 \(percent) パーセント")
    }
}

