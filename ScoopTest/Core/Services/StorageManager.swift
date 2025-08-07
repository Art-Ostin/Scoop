//
//  StorageManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/07/2025.
//

import Foundation
import FirebaseStorage
import UIKit
import SwiftUI

@Observable class StorageManager: StorageManaging {
    
    @ObservationIgnored private let userManager: CurrentUserStore
    private let storage = Storage.storage().reference()

    init(user: CurrentUserStore) {
        self.userManager = user
    }
    
    func imagePath(_ path: String) -> StorageReference {
        storage.child(path)
    }
    
    func getImageURL(path: String) async throws -> URL {
                        
        let url = try await imagePath(path).downloadURL()
        
        return updateImagePath(url: url)
        
    }
    
    func saveImage(data: Data) async throws -> String {
        guard let userId = userManager.user?.userId else  {return "Unverified User" }
        let filename = "\(UUID().uuidString).jpeg"
        let path = "users/\(userId)/\(filename)"
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await imagePath(path).putDataAsync(data, metadata: meta)
        return path
        }
    
    func deleteImage(path: String) async throws {
        try await imagePath(path).delete()
    }
    
    func updateImagePath(url: URL) -> URL {
        let urlString = url.absoluteString
        let newUrlString = urlString.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg", options: [.literal, .backwards])

        if let newURL = URL(string: newUrlString) {
            return newURL
        }
        return url
    }
}
