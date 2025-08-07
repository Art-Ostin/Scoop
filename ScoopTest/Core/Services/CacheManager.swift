//
//  CacheManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import Foundation
import UIKit
import SwiftUI



@Observable class CacheManager: ImageCaching {
    
    
    private let cache: NSCache<NSURL, UIImage>
    
    init() {
        cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
    }
    
    // fetches Image from Cache
    private func fetchImageFromCache(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    
    //Checks if image is in Cache, if not converts URL to Image, saves it to the Cache, and returns the image
    private func fetchImage(for url: URL) async throws -> UIImage {
        if let image = fetchImageFromCache(for: url) {
            print("Got image from Cache")
            return image
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        cache.setObject(image, forKey: url as NSURL, cost: data.count)
        return image
    }
    
    
    //Uses TaskGroup to fetch all the images quickly and saves them to
    func fetchProfileImages(profiles: [UserProfile]) async -> [UIImage] {
        
        let urls = profiles.flatMap { profile in
            profile.imagePathURL?.compactMap { URL(string: $0) } ?? []
        }
        var images: [UIImage] = []
        await withTaskGroup(of: UIImage?.self) { group in
            for url in urls {
                group.addTask {
                    try? await self.fetchImage(for: url)
                }
            }
            for await img in group {
                if let img { images.append(img) }
            }
        }
        return images
    }
}
