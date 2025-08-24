//
//  ContentView.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // 単語学習カード
                    NavCard(
                        title: "単語学習",
                        subtitle: "毎日コツコツ・SRS対応",
                        systemImage: "book.fill",
                        gradient: Gradient(colors: [.blue.opacity(0.8), .cyan.opacity(0.8)])
                    ) {
                        WordTrainerView()
                    }

                    // クイズカード
                    NavCard(
                        title: "クイズ（4択）",
                        subtitle: "10問で弱点チェック",
                        systemImage: "questionmark.circle.fill",
                        gradient: Gradient(colors: [.purple.opacity(0.85), .pink.opacity(0.85)])
                    ) {
                        QuizView()
                    }

                    // 文章添削カード
                    NavCard(
                        title: "文章添削",
                        subtitle: "AIでフランス語を校正",
                        systemImage: "text.badge.checkmark",
                        gradient: Gradient(colors: [.green.opacity(0.85), .teal.opacity(0.85)])
                    ) {
                        ProofreadView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("FrenchLearning")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// 共通カードビュー
struct NavCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let gradient: Gradient
    @ViewBuilder var destination: () -> Destination

    @State private var isPressed = false

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: systemImage)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.2)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.2)) { isPressed = false } }
        )
    }
}

#Preview { ContentView() }
