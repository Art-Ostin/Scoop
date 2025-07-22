//
//  StorageManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/07/2025.
//

import Foundation
import FirebaseStorage

class StorageManager {
    
    static let instance = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    func saveImage(data: Data) async throws -> (path: String, name: String) {
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        
        let path = "\(UUID().uuidString).jpeg"
        
        let returnedMetadata = try await storage.child(path).putDataAsync(data, metadata: meta)
        
        guard let returnedPath = returnedMetadata.path, let returnedName = returnedMetadata.name else {
            throw URLError(.badServerResponse)
        }
        
        return (returnedPath, returnedName)
    }
}

