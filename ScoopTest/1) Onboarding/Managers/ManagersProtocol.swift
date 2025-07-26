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
    func updateSex(userId: String, sex: String) async throws
    func updateAttractedTo(userId: String, attractedTo: String) async throws
    func updateYear(userId: String, year: String) async throws
    func updateHeight(userId: String, height: String) async throws
    func updateInterests(userId: String, interest: String) async throws
    func removeInterests(userId: String, interest: String) async throws
    func updateDegree(userId: String, degree: String) async throws
    func updateHometown(userId: String, hometown: String) async throws
    func updateName(userId: String, name: String) async throws
    func updateNationality(userId: String, nationality: String) async throws
    func removeNationality(userId: String, nationality: String) async throws
    func updateLookingFor(userId: String, lookingFor: String) async throws
    func updatePrompt(userId: String, promptIndex: Int, prompt: PromptResponse) async throws
    func updateDrinking(userId: String, drinking: String) async throws
    func updateSmoking(userId: String, smoking: String) async throws
    func updateMarijuana(userId: String, marijuana: String) async throws
    func updateDrugs(userId: String, drugs: String) async throws
    func updateLanguages(userId: String, languages: String) async throws
    func updateFavouriteMovie(userId: String, favouriteMovie: String) async throws
    func updateFavouriteSong(userId: String, favouriteSong: String) async throws
    func updateFavouriteBook(userId: String, favouriteBook: String) async throws
    func updateCharacter(userId: String, character: String) async throws
    func removeCharacter(userId: String, character: String) async throws
    func updateImagePath(userId: String, path: String, url: String) async throws
    func removeImagePath(userId: String, path: String, url: String) async throws
}


protocol StorageManaging {
    func getPath(path: String) -> StorageReference
    func getUrlForImage(path: String) async throws -> URL
    func saveImage(userId: String, data: Data) async throws -> String
    func getData(userId: String, path: String) async throws -> Data
    func getImage(userId: String, path: String) async throws -> UIImage
    func deleteImage(path: String) async throws
}
