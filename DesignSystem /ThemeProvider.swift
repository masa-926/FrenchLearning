//
//  ThemeProvider.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/09/01.
//

// ThemeProvider.swift
import SwiftUI

struct ThemeProvider<Content: View>: View {
  @AppStorage("app.theme") private var themeRaw: String = AppTheme.classic.rawValue
  let content: () -> Content
  var body: some View {
    let theme = AppTheme(rawValue: themeRaw) ?? .classic
    content().appTheme(theme)
  }
}

