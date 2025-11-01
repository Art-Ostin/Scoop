//
//  StorageManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/07/2025.
// Cannot Update Path Here as I need it for the DownloadURL and breaks if I update path before downloadURL

import Foundation
import FirebaseStorage
import SwiftUI


class StorageManager: StorageManaging {
    
    private let storage = Storage.storage().reference()
    
    func imagePath(_ path: String) -> StorageReference {
        storage.child(path)
    }
    
    //Want to be able to delete this (Shouldn't need to reference path to url as reference it directly in their profile
    func getImageURL(path: String) async throws -> URL {
        let vPath = variantPath(from: path)
        return try await imagePath(vPath).downloadURL()
    }
    
    func saveImage(data: Data, userId: String) async throws -> (path: String, url: URL) {
        let filename = "\(UUID().uuidString).jpeg"
        let basePath = "users/\(userId)/\(filename)"
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await imagePath(basePath).putDataAsync(data, metadata: meta)
        let vPath = variantPath(from: basePath)
        let vRef  = imagePath(vPath)
        for attempt in 0..<6 { // delays: 0.5s, 1s, 2s, 4s, 8s, 16s
            do {
                let url = try await vRef.downloadURL()
                return (vPath, url)
            } catch {
                print("THIS IS THE ERROR HERE!!!!!!!!!!!!!!!!! \(error)")
                let delaySeconds = 0.5 * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }
        return( "", URL(string: "")!)
    }
    
    func deleteImage(path: String) async throws {
        try await imagePath(path).delete()
    }
    
    private func variantPath(from originalPath: String, suffix: String = "_1350x1350") -> String {
        let u = URL(fileURLWithPath: originalPath)
        let dir = u.deletingLastPathComponent().path
        var base = u.deletingPathExtension().lastPathComponent
        if !base.hasSuffix(suffix) { base += suffix }
        let ext = u.pathExtension.isEmpty ? "jpeg" : u.pathExtension
        return "\(dir)/\(base).\(ext)"
    }
}
