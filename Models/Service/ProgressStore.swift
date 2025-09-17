//
//  Services: ProgressStore.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

// Services/ProgressStore.swift
import Foundation

final class ProgressStore {
static let shared = ProgressStore()
private let defaults = UserDefaults.standard
private let keyIndex = "word.currentIndex"

var currentIndex: Int {
get { defaults.integer(forKey: keyIndex) }
set { defaults.set(newValue, forKey: keyIndex) }
}
}
