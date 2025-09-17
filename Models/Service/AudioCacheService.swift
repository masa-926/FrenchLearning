//
//  AudioCacheService.swift
//  FrenchLearning
//
//  Created by 藤原匡都 on 2025/08/30.
//

import Foundation

final class AudioCacheService {
    static let shared = AudioCacheService()
    private let fm = FileManager.default

    func cachedURL(for remote: URL) -> URL {
        let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("audio_\(remote.lastPathComponent)")
    }

    func prefetch(_ urlString: String) {
        guard let u = URL(string: urlString) else { return }
        let dst = cachedURL(for: u)
        if fm.fileExists(atPath: dst.path) { return }
        URLSession.shared.downloadTask(with: u) { tmp, _, _ in
            guard let tmp else { return }
            try? self.fm.removeItem(at: dst)
            try? self.fm.copyItem(at: tmp, to: dst)
        }.resume()
    }
}

