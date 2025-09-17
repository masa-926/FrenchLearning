import Foundation

/// クイズでの誤答IDを、学習画面へ橋渡しするための超軽量バッファ
public final class MistakeBuffer {
    public static let shared = MistakeBuffer()
    private var ids: [String] = []
    private let lock = NSLock()
    private init() {}

    /// まとめて投入（重複は許容・あとでVM側が調整）
    public func seed(_ newIDs: [String]) {
        guard !newIDs.isEmpty else { return }
        lock.lock(); defer { lock.unlock() }
        ids.append(contentsOf: newIDs)
    }

    /// 全件取り出してクリア
    public func drain() -> [String] {
        lock.lock(); defer { lock.unlock() }
        let out = ids
        ids.removeAll()
        return out
    }
}

