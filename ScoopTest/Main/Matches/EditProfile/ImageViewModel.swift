//
//  ImageViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

@Observable class ImageViewModel {
    
    var pickerItems: [PhotosPickerItem?] = Array(repeating: nil, count: 6)
    var selectedImages: [UIImage?] = Array(repeating: nil, count: 6)
    var imagePaths:[String?] = .init(repeating: nil, count: 6)
    var imageURLs:[String?] = .init(repeating: nil, count: 6)
    var dep: AppDependencies
    
    init (dep: AppDependencies) {
        self.dep = dep
    }
    
    func seedFromCurrentUser() {
        guard let paths = dep.userStore.user?.imagePath,
              let urls  = dep.userStore.user?.imagePathURL
        else { return }
        let paddedPaths = (paths + Array(repeating: nil, count: 6)).prefix(6)
        let paddedURLs  = (urls  + Array(repeating: nil, count: 6)).prefix(6)
        imagePaths = Array(paddedPaths)
        imageURLs  = Array(paddedURLs)
    }
    
    func reloadEverything() async {
        try? await dep.userStore.loadUser()
        seedFromCurrentUser()
    }
    
    func loadImage(at index: Int) {
        
        guard let selection = pickerItems[index] else {return}

        Task {
            guard let user =  dep.userStore.user else {return}
            if let oldPath = imagePaths[index], let oldURL = imageURLs[index] {
                try? await dep.storageManager.deleteImage(path: oldPath)
                try? await dep.profileManager.update(userId: user.userId, values: [
                    .imagePath: FieldValue.arrayRemove([oldPath]),
                    .imagePathURL: FieldValue.arrayRemove([oldURL])
                ])
                await MainActor.run {
                    imagePaths[index] = nil
                    imageURLs[index] = nil
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
            let newPath = try await dep.storageManager.saveImage(userId: user.userId, data: data)
            let newURL = try await dep.storageManager.getUrlForImage(path: newPath)
            
            try await dep.profileManager.update(userId: user.userId, values: [
                .imagePath: FieldValue.arrayUnion([newPath]),
                .imagePathURL: FieldValue.arrayUnion([newURL.absoluteString]),
            ])
            
            try await dep.userStore.loadUser()
            
            await MainActor.run {
                imagePaths[index] = newPath
                imageURLs[index] = newURL.absoluteString
                pickerItems[index] = nil
            }
        }
    }

}
