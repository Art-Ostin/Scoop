//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//Structure: The data edits the 'draft' profile which is repeatedly updated to be displayed on the 'preview' 'view' screen. Images however depend on the images.

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

@MainActor
@Observable class EditProfileViewModel {
    
    @ObservationIgnored private let userRepo: userRepo
    @ObservationIgnored let imageLoader: ImageLoading
    @ObservationIgnored private let s: SessionManager
    @ObservationIgnored private let storageManager: StorageManaging

    var draft: UserProfile
    var images: [UIImage] = Array(repeating: placeholder, count: 6)

    var updatedFields: [UserProfile.Field : Any] = [:]
    var updatedImages: [Int: Data] = [:]
        
    init(imageLoader: ImageLoading, s: SessionManager, userRepo: userRepo, storageManager: StorageManaging, importedImages: [UIImage]) {
        self.imageLoader = imageLoader
        self.s = s
        self.userRepo = userRepo
        self.storageManager = storageManager
        self.images = importedImages
        self.draft = s.user
    }
    
    var user: UserProfile { s.user }
    
    var showSaveButton: Bool { !updatedFields.isEmpty || !updatedImages.isEmpty}
    
    func set<T: Equatable>(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, T>,  to value: T) {
        draft[keyPath: kp] = value
        if user[keyPath: kp] == value {
            updatedFields.removeValue(forKey: key)
        } else {
            updatedFields[key] = value
        }
    }
    
    func setPrompt(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, PromptResponse>, to value: PromptResponse) {
        draft[keyPath: kp] = value
        updatedFields[key] = ["prompt": value.prompt, "response": value.response]
    }
    
    func saveUser() async throws {
        guard !updatedFields.isEmpty else { return }
        try await userRepo.updateUser(userId: user.id, values: updatedFields)
    }
    
    func saveProfileChanges() async throws {
        try await saveUser()
        try await saveUpdatedImages()
    }
    
    func interestIsSelected(text: String) -> Bool {
        user.interests.contains(text) == true
    }
    
    func updateUser(values: [UserProfile.Field : Any]) async throws  {
        try await userRepo.updateUser(userId: user.id, values: values)
    }
}

//Image Functionality
extension EditProfileViewModel {
    //Images
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()

    func changeImage(image: ImageSlot) async throws {
        let index = image.index
        await MainActor.run {
            if images.indices.contains(index) {images[index] = image.image}
        }
        if let data = image.jpegData {
            updatedImages[index] = data
        }
    }
    
    func saveUpdatedImages() async throws {
         let updates = updatedImages
         var paths = user.imagePath
         var urls  = user.imagePathURL
         if paths.count < 6 { paths += Array(repeating: "", count: 6 - paths.count) }
         if urls.count  < 6 { urls  += Array(repeating: "", count: 6 - urls.count) }
         let userId = user.id
         
         struct ImgResult { let index: Int; let path: String; let url: URL }
         
         let results: [ImgResult] = try await withThrowingTaskGroup(of: ImgResult.self, returning: [ImgResult].self) { group in
             for (index, data) in updates {
                 let oldPath = paths[index].isEmpty ? nil : paths[index]
                 let oldURLString = urls[index]
                 let oldURL = oldURLString.isEmpty ? nil : URL(string: oldURLString)
                 group.addTask {
                     if let oldURL { await self.imageLoader.removeImage(for: oldURL) }
                     if let oldPath { try? await self.storageManager.deleteImage(path: oldPath) }
                     let saveResult = try await self.storageManager.saveImage(data: data, userId: userId)
                     let originalPath = saveResult.path
                     let url = saveResult.url
                     let resized = originalPath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
                     return ImgResult(index: index, path: resized, url: url)
                 }
             }
             var tmp: [ImgResult] = []
             for try await r in group { tmp.append(r) }
             return tmp
         }
         for r in results {
             paths[r.index] = r.path
             urls[r.index]  = r.url.absoluteString
         }
         try await userRepo.updateUser(userId: user.id, values: [.imagePath: paths, .imagePathURL: urls])
    }
    
    @MainActor
    func loadImages() async {
        self.images = await imageLoader.loadProfileImages([user])
    }
}


/*
 !updatedFieldsArray.isEmpty ||
 
 var updatedFieldsArray: [(field: UserProfile.Field, value: [String], add: Bool)] = []
 
 try await saveUserArray()

 func saveUserArray() async throws {
     guard !updatedFieldsArray.isEmpty else {
         print("UpdatedFields Array empty not calling this function!")
         return
     }
     for (field, value, add) in updatedFieldsArray {
         let data: [UserProfile.Field : [String]] = [field: value]
         try await userRepo.updateUserArray(userId: user.id, values: data, add: add)
     }
 }
 
 
 */
