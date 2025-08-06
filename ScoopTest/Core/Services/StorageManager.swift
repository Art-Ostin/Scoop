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
        try await imagePath(path).downloadURL()
    }
    
    func saveImage(data: Data) async throws -> String {
        guard let userId = userManager.user?.userId else  {return "Unverified User" }
        let filename = "\(UUID().uuidString).jpeg"
        let path = "users/\(userId)/\(filename)"
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await imagePath(path).putDataAsync(data, metadata: meta)
        return getNewPath(original: path)
        }
    
    func getImage(path: String) async throws -> UIImage {
        let imageData = try await imagePath(path).data(maxSize: 3 * 1024 * 1024)
        if let image = UIImage(data: imageData) {return image} else {return UIImage()}
    }
    
    func deleteImage(path: String) async throws {
        try await imagePath(path).delete()
    }
    
    
    private func getNewPath(original: String) -> String {
        let baseName = (original as NSString).deletingPathExtension
        let ext = (original as NSString).pathExtension
        
        return "\(baseName)_1350x1350.\(ext)"
    }
    
}




//Original Code
/*
 
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
         try await imagePath(path).downloadURL()
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
     
     func getImage(path: String) async throws -> UIImage {
         let imageData = try await imagePath(path).data(maxSize: 3 * 1024 * 1024)
         if let image = UIImage(data: imageData) {return image} else {return UIImage()}
     }
     
     func deleteImage(path: String) async throws {
         try await imagePath(path).delete()
     }
 }
 
 */
