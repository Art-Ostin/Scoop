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
    
    
    @ObservationIgnored private var userManager: CurrentUserStore
    
    init(user: CurrentUserStore) {
        self.userManager = user
    }
    
    private let storage = Storage.storage().reference()
    
    func getImagePath(path: String) -> StorageReference {
        Storage.storage().reference(withPath: path)
    }

    func getImageURL(path: String) async throws -> URL {
        try await  getImagePath(path: path).downloadURL()
    }
    
    func saveImage(data: Data) async throws -> String {
        guard let userId = userManager.user?.userId else  {return "Unverified User" }
        let filename = "\(UUID().uuidString).jpeg"
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        let result = try await storage.child("users").child(userId).child(filename).putDataAsync(data, metadata: meta)
        return result.path ?? ""
        }
    
    func getImage(path: String) async throws -> UIImage {
        let imageData = try await storage.child(path).data(maxSize: 3 * 1024 * 1024)
        if let image = UIImage(data: imageData) {return image} else {return UIImage()}
    }
    
    func deleteImage(path: String) async throws {
        try await getImagePath(path: path).delete()
    }
}
