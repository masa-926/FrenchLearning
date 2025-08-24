//
//  Features:Proofread:ProofreadResult.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import Foundation

struct ProofreadResult: Codable {
    let corrected: String
    let explanations: [String]
}

