//
//  Haptics.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/24.
//

import UIKit

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func light()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
