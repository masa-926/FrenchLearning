//
//  AttributionView .swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/31.
//

import SwiftUI

struct AttributionsView: View {
    var body: some View {
        List {
            Section("出典 / ライセンス") {
                LabeledContent("Wiktionary", value: "CC BY-SA 3.0 / GFDL（抜粋&出典表記）")
                LabeledContent("Lefff (Alexina)", value: "LGPL-LR")
                LabeledContent("Universal Dependencies (fr)", value: "GSD=CC BY-SA, Sequoia=LGPL-LR")
                LabeledContent("WOLF (WordNet Libre du Français)", value: "CeCILL-C")
                LabeledContent("Lexique 3", value: "CC BY-SA 4.0")
            }
            Section("リンク") {
                Link("Wiktionary", destination: URL(string: "https://fr.wiktionary.org/")!)
                Link("UD Project", destination: URL(string: "https://universaldependencies.org/")!)
                Link("Lefff / Alexina", destination: URL(string: "https://alpage.inria.fr/~sagot/lefff.html")!)
                Link("WOLF", destination: URL(string: "https://wonef.fr/")!)
                Link("Lexique 3", destination: URL(string: "http://www.lexique.org/")!)
            }
        }
        .navigationTitle("出典とライセンス")
        Section("Linguistic Resources") {
            LabeledContent("Wiktionary", value: "CC BY-SA 3.0 — Excerpts cached with title & revision")
            LabeledContent("Lefff (verbs)", value: "LGPL-LR — Data subset bundled; source acknowledged")
            LabeledContent("Universal Dependencies (GSD/Sequoia)", value: "CC BY-SA — Aggregated pattern counts")
        }

    }
}
