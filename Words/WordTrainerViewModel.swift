//
//  WordTrainerViewModel.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

// Features/Words/WordTrainerViewModel.swift
import SwiftUI

final class WordTrainerViewModel: ObservableObject {
@Published var words: [VocabWord] = []
@Published var index: Int = ProgressStore.shared.currentIndex
@Published var showMeaning = false

var current: VocabWord? { words.isEmpty ? nil : words[index % words.count] }

init() { load() }

func load() {
guard let url = Bundle.main.url(forResource: "wordset_fr_ja", withExtension: "json"),
let data = try? Data(contentsOf: url),
let list = try? JSONDecoder().decode([VocabWord].self, from: data) else { return }
words = list.shuffled()
}

func reveal() { showMeaning = true }

func next() {
guard !words.isEmpty else { return }
showMeaning = false
index = (index + 1) % words.count
ProgressStore.shared.currentIndex = index
}
}
