//
//  imageLoader.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import Foundation
import UIKit
import SwiftUI

//Injecting ImageLoader around the app as don't want to have multiple Caches open

class ImageLoader: ImageLoading  {
    
    private let cache: NSCache<NSURL, UIImage>

    init() {
        cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
    }

    private func fetchImageFromCache(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func removeImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
    
    func fetchImage(for url: URL) async throws -> UIImage {
        if let image = fetchImageFromCache(for: url) {
            return image
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        if let image = UIImage(data: data) {
            cache.setObject(image, forKey: url as NSURL, cost: data.count)
            return image
        }
        return UIImage()
    }
    
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage? {
        guard
            let urlString = profile.imagePathURL.first,
            let url = URL(string: urlString)
        else {return nil}
        return try await fetchImage(for: url)
    }
    
    @discardableResult
    func loadProfileImages(_ profiles: [UserProfile]) async -> [UIImage] {
        let urls = profiles.flatMap { profile in
            profile.imagePathURL.compactMap { URL(string: $0) }
        }
        var images = Array<UIImage?>(repeating: nil, count: urls.count)
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    do {
                        let image = try await self.fetchImage(for: url)
                        return (index, image)
                    } catch {
                        print("unable to add images to cache")
                        return (index, nil)
                    }
                }
            }
            for await (index, img) in group {
                if let img { images[index] = img }
            }
            print("Images saved to cache")
        }
        return images.compactMap { $0 }
    }
    
    @discardableResult
    private func prewarmCache(for profiles: [UserProfile]) -> Task<Void, Never>? {
        guard !profiles.isEmpty else { return nil }
        return Task.detached(priority: .utility) { [cache] in
            await cache.loadProfileImages(profiles)
        }
    }
}

