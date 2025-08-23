//
//  Words: VocabWord.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

// Features/Words/VocabWord.swift
import Foundation

struct VocabWord: Identifiable, Codable, Hashable {
let id: String
let term: String
let meaningJa: String
let pos: String?
let example: String?
}
