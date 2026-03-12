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
actor ImageLoader  {
    
    private let cache: NSCache<NSURL, UIImage>

    init() {
        cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
    }

    private func fetchImageFromCache(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    private func addImageToCache(url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let image = UIImage(data: data) {
            cache.setObject(image, forKey: url as NSURL, cost: data.count)
            return image
        }
        return UIImage()
    }
    
    func removeImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
    
    func fetchImage(for url: URL) async throws -> UIImage {
        if let image = fetchImageFromCache(for: url) { return image}
        return try await addImageToCache(url: url)
    }
    
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage {
        if let urlString = profile.imagePathURL.first, let url = URL(string: urlString) {
            return try await fetchImage(for: url)
        }
        return UIImage()
    }
    
    func loadProfileImages(_ profile: UserProfile) async -> [UIImage] {
        
        //1. Fetch the imageurls from the profile
        let urls = profile.imagePathURL.compactMap { URL(string: $0) }

        //2. Open task group so more efficient
        return await withTaskGroup(of: (Int, UIImage?).self) { group in
            
            //3. Create an empty array of six images
            var images = Array<UIImage?>(repeating: nil, count: urls.count)
            
            //4. For each url get the Index and Image
            for (index, url) in urls.enumerated() {
                group.addTask {
                    let image = try? await self.fetchImage(for: url)
                    return (index, image)
                }
            }
            //5. Add the image back at the specific index (so order retained)
            for await (index, img) in group {
                if let img {
                    images[index] = img
                }
            }
            //6. Return the images back
            return images.compactMap { $0 }
        }
    }
    
    func addImagesToCache(for profiles: [UserProfile]) async {
        await withTaskGroup(of: Void.self) { group in
            for profile in profiles {
                group.addTask {
                    for urlString in profile.imagePathURL {
                        if let url = URL(string: urlString) {
                           _ = try? await self.addImageToCache(url: url)
                        }
                    }
                }
            }
        }
    }
}


