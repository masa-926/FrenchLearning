//
//  DesignSystem.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/09/01.
//

// DesignSystem.swift
import SwiftUI

// 名前衝突しにくい軽量ネームスペース
enum DS {
  enum Spacing {
    static let xs: CGFloat = 6, s: CGFloat = 10, m: CGFloat = 16, l: CGFloat = 24, xl: CGFloat = 32
  }
  enum Radius {
    static let card: CGFloat = 20, chip: CGFloat = 14, button: CGFloat = 12
  }
  enum Colors {
    static let bgCard = Color(.secondarySystemBackground)
    static let bgCanvas = Color(.systemGroupedBackground)
    static let stroke = Color(.quaternaryLabel)
    static let textSecondary = Color.secondary
    static let accent = Color.accentColor     // 将来は Color("AccentPrimary") に差し替え
  }
  enum Gradients {
    static let blue   = Gradient(colors: [Color.blue.opacity(0.85), .cyan.opacity(0.85)])
    static let purple = Gradient(colors: [Color.purple.opacity(0.9), .pink.opacity(0.85)])
    static let green  = Gradient(colors: [Color.green.opacity(0.9),  .teal.opacity(0.85)])
    static let orange = Gradient(colors: [.orange, .pink])
    static let indigo = Gradient(colors: [.indigo, .blue])
  }
  enum Anim {
    static func spring() -> Animation {
      UIAccessibility.isReduceMotionEnabled ? .default : .interactiveSpring(response: 0.28, dampingFraction: 0.88)
    }
  }
}

// 将来のスキン変更に備えたテーマ
enum AppTheme: String, CaseIterable, Identifiable { case classic, vibrant; var id: String { rawValue } }

// Environment 経由でどこでも参照できるように
private struct AppThemeKey: EnvironmentKey { static let defaultValue: AppTheme = .classic }
extension EnvironmentValues { var appTheme: AppTheme { get { self[AppThemeKey.self] } set { self[AppThemeKey.self] = newValue } } }
extension View { func appTheme(_ t: AppTheme) -> some View { environment(\.appTheme, t) } }

// 共通コンポーネント化（カード／プライマリーボタン）
struct CardContainer: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(DS.Spacing.m)
      .background(RoundedRectangle(cornerRadius: DS.Radius.card).fill(DS.Colors.bgCard))
      .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.stroke, lineWidth: 0.5))
      .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
  }
}
extension View { func cardContainer() -> some View { modifier(CardContainer()) } }

struct PrimaryButtonStyleDS: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(RoundedRectangle(cornerRadius: DS.Radius.button).fill(DS.Colors.accent.opacity(configuration.isPressed ? 0.7 : 1)))
      .foregroundStyle(.white)
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .animation(DS.Anim.spring(), value: configuration.isPressed)
  }
}

