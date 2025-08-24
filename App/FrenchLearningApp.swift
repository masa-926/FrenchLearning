//
//  App: FrenchLearningApp.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import SwiftUI

@main
struct FrenchLearningApp: App {
    @StateObject private var net = NetworkMonitor()   // ← 追加

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(net)              // ← 追加：全画面で参照可能に
        }
    }
}
