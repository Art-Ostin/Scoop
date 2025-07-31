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
    
    
    init() {}
    
    private let storage = Storage.storage().reference()
    
    private let resizedSuffix = "_1350x1350"

    private func resizedPath(for path: String) -> String {
        path.replacingOccurrences(of: ".jpeg", with: "\(resizedSuffix).jpeg")
    }
    
    private func userReference(userId: String) -> StorageReference {
        storage.child("users").child(userId)
    }
    
    func getResizedUrlForImage(path: String) async throws -> URL {
        let rPath = resizedPath(for: path)
        let ref = getPath(path: rPath)
        var attempts = 10
        while attempts > 0 {
            do {
                return try await ref.downloadURL()
            } catch {
                attempts -= 1
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        return try await ref.downloadURL()
    }
    
    
    func getPath(path: String) -> StorageReference {
        Storage.storage().reference(withPath: path)
    }
    
    func getUrlForImage(path: String) async throws -> URL {
        let path = resizedPath(for: path)
        return try await getPath(path: path).downloadURL()
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
        let path = resizedPath(for: path)
        return try await storage.child(path).data(maxSize: 3 * 1024 * 1024)
    }
    
    func getImage(userId: String, path: String) async throws -> UIImage {
        let data = try await getData(userId: userId, path: path)
        guard let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        return image
    }
    
    func deleteImage(path: String) async throws {
        let path = resizedPath(for: path)
        try await getPath(path: path).delete()
    }
    
}
