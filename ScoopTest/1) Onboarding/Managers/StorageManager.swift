//
//  StorageManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/07/2025.
//

import Foundation
import FirebaseStorage
import UIKit


class StorageManager: StorageManaging {
    
    static let instance = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    
    private func userReference(userId: String) -> StorageReference {
        storage.child("users").child(userId)
    }
    
    func getPath(path: String) -> StorageReference {
        Storage.storage().reference(withPath: path)
    }
    
    func getUrlForImage(path: String) async throws -> URL {
        try await  getPath(path: path).downloadURL()
    }
    
    func saveImage(userId: String, data: Data) async throws -> String {
        let filename = "\(UUID().uuidString).jpeg"
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        let result = try await userReference(userId: userId).child(filename).putDataAsync(data, metadata: meta)
        guard let path = result.path else { throw URLError(.badServerResponse)}
        return path
    }
    
    func getData(userId: String, path: String) async throws -> Data  {
        try await storage.child(path).data(maxSize: 3 * 1024 * 1024)
    }
    
    func getImage(userId: String, path: String) async throws -> UIImage {
        let data = try await getData(userId: userId, path: path)
        guard let image = UIImage(data: data) else {
            throw URLError(.badServerResponse )
        }
        return image
    }
    
    func deleteImage(path: String) async throws {
        try await getPath(path: path).delete()
    }
}
