//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

@MainActor
@Observable class EditProfileViewModel {
    
    @ObservationIgnored private let userManager: UserManager
    @ObservationIgnored let cacheManager: CacheManaging
    @ObservationIgnored private let s: SessionManager
    @ObservationIgnored private let storageManager: StorageManaging

    var draft: UserProfile
    
    var updatedFields: [UserProfile.Field : Any] = [:]
    var updatedFieldsArray: [(field: UserProfile.Field, value: [String], add: Bool)] = []
    var updatedImages: [(index: Int, data: Data)] = []
    
    init(cacheManager: CacheManaging, s: SessionManager, userManager: UserManager, storageManager: StorageManaging) {
        self.cacheManager = cacheManager
        self.s = s
        self.userManager = userManager
        self.storageManager = storageManager
        self.draft = s.user
    }
    
    var user: UserProfile { s.user }
    
    var showSaveButton: Bool { !updatedFields.isEmpty || !updatedFieldsArray.isEmpty || !updatedImages.isEmpty}
    
    func set<T>(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, T>,  to value: T) {
        draft[keyPath: kp] = value
        updatedFields[key] = value
    }
    
    func setPrompt(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, PromptResponse>, to value: PromptResponse) {
        draft[keyPath: kp] = value
        updatedFields[key] = ["prompt": value.prompt, "response": value.response]
    }
    
    func setArray(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, [String]>,  to elements: [String], add: Bool) {
        if add == true {
            draft[keyPath: kp].append(contentsOf: elements)
        } else {
            let removeSet = Set(elements)
            draft[keyPath: kp].removeAll { removeSet.contains($0) }
        }
        updatedFieldsArray.append((field: key, value: elements, add: add))
    }

    
    func saveUser() async throws {
        guard !updatedFields.isEmpty else { return }
        try await userManager.updateUser(userId: user.id, values: updatedFields)
    }
        
    func saveUserArray() async throws {
        guard !updatedFieldsArray.isEmpty else { return }
        for (field, value, add) in updatedFieldsArray {
            let data: [UserProfile.Field : [String]] = [field: value]
            try await userManager.updateUserArray(userId: user.id, values: data, add: add)
        }
    }
    
    func saveUpdatedImages() async throws {
        /*
         let updates = updatedImages
         let snapshotSlots = slots
         var paths = user.imagePath
         var urls  = user.imagePathURL
         if paths.count < 6 { paths += Array(repeating: "", count: 6 - paths.count) }
         if urls.count  < 6 { urls  += Array(repeating: "", count: 6 - urls.count) }
         let userId = user.id
         
         struct ImgResult { let index: Int; let path: String; let url: URL }
         
         let results: [ImgResult] = try await withThrowingTaskGroup(of: ImgResult.self, returning: [ImgResult].self) { group in
             for (index, data) in updates {
                 let oldPath = snapshotSlots[index].path
                 let oldURL  = snapshotSlots[index].url
                 
                 group.addTask {
                     if let oldURL { await self.cacheManager.removeImage(for: oldURL) }
                     if let oldPath { try? await self.storageManager.deleteImage(path: oldPath) }
                     let originalPath = try await self.storageManager.saveImage(data: data, userId: userId)
                     let url = try await self.storageManager.getImageURL(path: originalPath)
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
         try await userManager.updateUser(userId: user.id, values: [.imagePath: paths, .imagePathURL: urls])
         */
    }
    
    
    
    func saveProfileChanges() async throws {
        try await saveUser()
        try await saveUserArray()
        try await saveUpdatedImages()
    }

    
    

    
    
    //Images
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()
    var images: [UIImage] = Array(repeating: placeholder, count: 6)
    
    @MainActor
    func assignSlots() async {
        let paths = user.imagePath
        let urlStrings = user.imagePathURL
        let urls = urlStrings.compactMap(URL.init(string:))
        var newImages = Array(repeating: Self.placeholder, count: 6)
        for i in 0..<min(urls.count, 6) {
            if let img = try? await cacheManager.fetchImage(for: urls[i]) {
                newImages[i] = img
            }
        }
        for i in 0..<6 {
            slots[i].path = i < paths.count ? paths[i] : nil
            slots[i].url  = i < urls.count  ? urls[i]  : nil
            slots[i].pickerItem = nil
        }
        images = newImages
    }
    
    func changeImage(at index: Int) async throws {
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
        else { return }
        
        await MainActor.run {
            if images.indices.contains(index) { images[index] = uiImage }
        }
        
        if let i = updatedImages.firstIndex(where: {$0.index == index}) {
            updatedImages[i] = (index: index, data: data)
        } else {
            updatedImages.append((index: index, data: data))
        }
    }
    
    func interestIsSelected(text: String) -> Bool {
        user.interests.contains(text) == true
    }
    
    func updateUser(values: [UserProfile.Field : Any]) async throws  {
        try await userManager.updateUser(userId: user.id, values: values)
    }
}

/*
//    func fetchUserField<T>(_ key: KeyPath<UserProfile, T>) -> T {
//        user[keyPath: key]
//    }
 */


/*
 */
