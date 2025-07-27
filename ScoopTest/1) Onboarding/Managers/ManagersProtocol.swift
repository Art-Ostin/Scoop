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
    func createUser(email: String, password: String) async throws
    func signInUser(email: String, password: String) async throws
    func getAuthenticatedUser() throws -> AuthenticatedUser
    func signOutUser() throws
}

protocol ProfileManaging {
    func createProfile(profile: UserProfile) async throws
    func getProfile(userId: String) async throws -> UserProfile
    func update(userId: String, values: [UserProfile.CodingKeys: Any]) async throws
    func updatePrompt(userId: String, promptIndex: Int, prompt: PromptResponse) async throws
}


protocol StorageManaging {
    func getPath(path: String) -> StorageReference
    func getUrlForImage(path: String) async throws -> URL
    func saveImage(userId: String, data: Data) async throws -> String
    func getData(userId: String, path: String) async throws -> Data
    func getImage(userId: String, path: String) async throws -> UIImage
    func deleteImage(path: String) async throws
}
