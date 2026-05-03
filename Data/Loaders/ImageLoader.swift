//
//  imageLoader.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/07/2025.
//

import Foundation
import UIKit
import SwiftUI
import CryptoKit

//Injecting ImageLoader around the app as don't want to have multiple Caches open
actor ImageLoader: ImageLoading  {

    //Warning Claude Code up to 'removeImage' for improving image load time. 
    private let cache: NSCache<NSURL, UIImage>
    private var inFlight: [NSURL: Task<UIImage, Error>] = [:]
    private nonisolated let diskCacheURL: URL
    private nonisolated let maxDiskBytes: Int = 150 * 1024 * 1024

    init() {
        cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("profile-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        diskCacheURL = dir
    }

    private func loadImage(url: URL) async throws -> UIImage {
        if let (image, cost) = readDisk(for: url) {
            cache.setObject(image, forKey: url as NSURL, cost: cost)
            return image
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { return UIImage() }
        cache.setObject(image, forKey: url as NSURL, cost: data.count)
        writeDisk(data: data, for: url)
        let dir = diskCacheURL
        let cap = maxDiskBytes
        Task.detached { Self.enforceDiskLimit(in: dir, max: cap) }
        return image
    }

    private nonisolated func diskFile(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return diskCacheURL.appendingPathComponent(name)
    }

    private nonisolated func readDisk(for url: URL) -> (UIImage, Int)? {
        let file = diskFile(for: url)
        guard let data = try? Data(contentsOf: file),
              let image = UIImage(data: data) else { return nil }
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: file.path
        )
        return (image, data.count)
    }

    private nonisolated func writeDisk(data: Data, for url: URL) {
        try? data.write(to: diskFile(for: url), options: .atomic)
    }

    private static func enforceDiskLimit(in dir: URL, max cap: Int) {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let urls = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: keys
        ) else { return }

        struct Entry { let url: URL; let size: Int; let date: Date }
        var entries: [Entry] = []
        var total = 0

        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  let size = values.fileSize,
                  let date = values.contentModificationDate else { continue }
            entries.append(Entry(url: url, size: size, date: date))
            total += size
        }

        if total <= cap { return }
        entries.sort { $0.date < $1.date }
        for entry in entries {
            if total <= cap { break }
            try? fm.removeItem(at: entry.url)
            total -= entry.size
        }
    }

    func removeImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
        try? FileManager.default.removeItem(at: diskFile(for: url))
    }

    func fetchImage(for url: URL) async throws -> UIImage {
        let key = url as NSURL

        if let image = cache.object(forKey: key) { return image }

        if let task = inFlight[key] {
            return try await task.value
        }

        let task = Task<UIImage, Error> {
            try await self.loadImage(url: url)
        }

        inFlight[key] = task
        defer { inFlight[key] = nil }

        return try await task.value
    }
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage? {
        if let urlString = profile.imagePathURL.first, let url = URL(string: urlString) {
            let image =  try await fetchImage(for: url)
            return image
        } else {
            return nil
        }
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
    
    func addProfileImagesToCache(for profiles: [UserProfile]) {
        let urls = profiles.flatMap(\.imagePathURL).compactMap(URL.init(string:))
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask { _ = try? await self.fetchImage(for: url) }
                }
            }
        }
    }
}


