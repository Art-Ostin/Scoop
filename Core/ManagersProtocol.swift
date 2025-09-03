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


protocol FirestoreService {
    func set<T: Encodable> (_ path: String, value: T) async throws
    func update(_ path: String, fields: [String : Any]) async throws
    func get<T: Decodable>(_ path: String) async throws -> T
    func listen<T: Decodable>(_ path: String) -> AsyncThrowingStream<T?, Error>
}




protocol AuthManaging {
    func createAuthUser(email: String, password: String) async throws -> AuthDataResult
    func signInAuthUser(email: String, password: String) async throws
    func fetchAuthUser () async -> String?
    func signOutAuthUser() throws
    func deleteAuthUser() async throws
    func authStateStream() -> AsyncStream<String?>
}

protocol StorageManaging {
    func imagePath(_ imageId: String) -> StorageReference
    func getImageURL(path: String) async throws -> URL
    func saveImage(data: Data, userId: String) async throws -> String
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
