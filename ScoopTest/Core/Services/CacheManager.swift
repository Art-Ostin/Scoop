//
//  CacheManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import Foundation
import UIKit



@Observable class CacheManager: ImageCaching {
    
    private let cache = NSCache<NSURL, UIImage>
    
    init() {
        cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
    }
    
    
    func addProfileImagesToCache(profile: UserProfile) async {
        let urls = profile.imagePathURL?.compactMap { URL(string: $0) } ?? []
        await prefetch(urls: urls)
    }
    
    
    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func fetchImage(for url: URL) async throws -> UIImage {
        if let cachedImage = cachedImage(for: url) {
            return cachedImage
        }
        let (data,_) = try await URLSession.shared.data(from: url)
        guard let img = UIImage(data: data) else {throw URLError(.badServerResponse)}
        cache.setObject(img, forKey: url as NSURL)
        return img
    }
    
    
    func prefetch(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                if cachedImage(for: url) == nil {
                    group.addTask { [weak self] in
                        guard let self else { return }
                        _ = try? await self.fetchImage(for: url)
                    }
                }
            }
        }
    }
}
