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
    func set<T: Encodable> (_ path: String, value: T) throws
    func add<T: Encodable> (_ path: String, value: T) throws -> String
    func get<T: Decodable>(_ path: String) async throws -> T
    func increment(_ path: String, by deltas: [String: Int64])
    func update(_ path: String, fields: [String : Any]) async throws
    func delete(_ path: String) async throws
    func listenD<T: Decodable>(_ path: String) -> AsyncThrowingStream<T?, Error>
    func fetchFromCollection<T: Decodable>( _ collectionPath: String, filters: [FSWhere], orderBy: FSOrder?, limit: Int?) async throws -> [T]
    func streamCollection<T: Decodable>(_ collectionPath: String, filters: [FSWhere], orderBy: FSOrder?, limit: Int?) -> AsyncThrowingStream<FSCollectionEvent<T>, Error>
}



protocol AuthManaging {
    func createAuthUser(email: String, password: String) async throws -> AuthDataResult
    func signInAuthUser(email: String, password: String) async throws
    func fetchAuthUser () async -> User?
    func signOutAuthUser() throws
    func deleteAuthUser() async throws
    func authStateStream() -> AsyncStream<String?>
}

protocol StorageManaging {
    func imagePath(_ imageId: String) -> StorageReference
    func getImageURL(path: String) async throws -> URL
    func saveImage(data: Data, userId: String) async throws -> (path: String, url: URL)
    func deleteImage(path: String) async throws
}

protocol CacheManaging {
    @discardableResult
    func loadProfileImages(_ profiles: [UserProfile]) async -> [UIImage]
    func fetchImage(for url: URL) async throws -> UIImage
    func removeImage(for url: URL)
    func fetchFirstImage(profile: UserProfile) async throws -> UIImage? 
}

