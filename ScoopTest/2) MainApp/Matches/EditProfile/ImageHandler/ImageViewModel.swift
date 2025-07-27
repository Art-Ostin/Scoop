//
//  ImageViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import Foundation
import SwiftUI
import PhotosUI

@Observable class ImageViewModel {
    
    var pickerItems: [PhotosPickerItem?] = Array(repeating: nil, count: 6)
    var selectedImages: [UIImage?] = Array(repeating: nil, count: 6)
    var imagePaths:[String?] = .init(repeating: nil, count: 6)
    var imageURLs:[String?] = .init(repeating: nil, count: 6)
    
    
    let storageManager: StorageManaging
    let userStore: CurrentUserStore
    let profileManager: ProfileManaging
    
    
    init (storageManager: StorageManaging, userStore: CurrentUserStore, profileManager: ProfileManaging) {
        self.userStore = userStore
        self.storageManager = storageManager
        self.profileManager = profileManager
    }
    
    
    func seedFromCurrentUser() {
        guard let paths = userStore.user?.imagePath,
              let urls  = userStore.user?.imagePathURL
        else { return }
        let paddedPaths = (paths + Array(repeating: nil, count: 6)).prefix(6)
        let paddedURLs  = (urls  + Array(repeating: nil, count: 6)).prefix(6)
        imagePaths = Array(paddedPaths)
        imageURLs  = Array(paddedURLs)
    }
    
    func reloadEverything() async {
      try? await userStore.loadUser()
        seedFromCurrentUser()
        
    }
    
    func loadImage(at index: Int, dependencies: AppDependencies) {
        
        let manager = dependencies.profileManager
        
        
        guard let selection = pickerItems[index] else {return}

        Task {
            guard let user =  userStore.user else {return}
            if let oldPath = imagePaths[index],
                let oldURLs = imageURLs[index]
                
                {
                try? await storageManager.deleteImage(path: oldPath)
                
                try? await manager.removeImagePath(userId: user.userId , path: oldPath, url: oldURLs)
                
                await MainActor.run {
                    imagePaths[index]     = nil
                    selectedImages[index] = nil
                }
            }
            guard
                let data = try? await selection.loadTransferable(type: Data.self),
                let uiImg = UIImage(data: data)
            else { return }
            
            await MainActor.run {
                selectedImages[index] = uiImg
            }
            let newPath = try await storageManager.saveImage(userId: user.userId, data: data)
            let newURL = try await storageManager.getUrlForImage(path: newPath)
            try await profileManager.updateImagePath(userId: user.userId, path: newPath, url: newURL.absoluteString)
            try await userStore.loadUser()
            
            await MainActor.run {
                imagePaths[index] = newPath
                imageURLs[index] = newURL.absoluteString
                pickerItems[index] = nil
            }
        }
    }

}
