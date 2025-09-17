import SwiftUI

public struct RelatedWordsSheet: View {
    public let items: [VocabRelated]
    public let pick: (VocabRelated) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(items: [VocabRelated], pick: @escaping (VocabRelated) -> Void) {
        self.items = items
        self.pick = pick
    }

    public var body: some View {
        NavigationStack {
            List(items, id: \.self) { r in
                Button {
                    pick(r)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(r.term).font(.headline)
                            if let p = r.pos, !p.isEmpty {
                                Text(p).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        if let ja = r.ja, !ja.isEmpty {
                            Text(ja).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("関連語")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

