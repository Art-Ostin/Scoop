//
//  CacheManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import Foundation
import UIKit
import SwiftUI



class CacheManager: CacheManaging  {
    
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
        print("Function called")
        do {
            print("docatch part called")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("got data")
            print(data)
            if let image = UIImage(data: data) {
                print("added Image to cache")
                cache.setObject(image, forKey: url as NSURL, cost: data.count)
                return image
            }
        } catch {
            print(error)
        }
        print("no image added")
        return UIImage()
    }
    
    
    
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage? {
        guard
            let urlString = profile.imagePathURL?.first,
            let url = URL(string: urlString)
        else {return nil}
        return try await fetchImage(for: url)
    }
    
    
    @discardableResult
    func loadProfileImages(_ profiles: [UserProfile]) async -> [UIImage] {
        let urls = profiles.flatMap { profile in
            profile.imagePathURL?.compactMap { URL(string: $0) } ?? []
        }
        var images: [UIImage] = []
        await withTaskGroup(of: UIImage?.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        return try await self.fetchImage(for: url)
                    } catch {
                        print("unable to add images to cache")
                        return nil
                    }
                }
            }
            for await img in group {
                if let img { images.append(img) }
            }
        }
        return images
    }    
}
