//
//  ManagersProtocol.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit


protocol AuthenticationManaging {
    func createAuthUser(email: String, password: String) async throws
    func signInAuthUser(email: String, password: String) async throws
    func getAuthUser() throws -> AuthenticatedUser
    func signOutAuthUser() throws
}

protocol StorageManaging {
    func imagePath(_ imageId: String) -> StorageReference
    func getImageURL(path: String) async throws -> URL
    func saveImage(data: Data) async throws -> String
    func deleteImage(path: String) async throws
    func updateImagePath(url: URL) -> URL
}

protocol CacheManaging {
    @discardableResult
    func loadProfileImages(_ profiles: [UserProfile]) async -> [UIImage]
    func fetchImage(for url: URL) async throws -> UIImage
    func removeImage(for url: URL)
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage? 
}
