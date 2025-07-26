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
    
    init() {
        
    }

    func seedFromCurrentUser() {
        guard let paths = CurrentUserStore.shared.user?.imagePath,
              let urls  = CurrentUserStore.shared.user?.imagePathURL
        else { return }
        let paddedPaths = (paths + Array(repeating: nil, count: 6)).prefix(6)
        let paddedURLs  = (urls  + Array(repeating: nil, count: 6)).prefix(6)
        imagePaths = Array(paddedPaths)
        imageURLs  = Array(paddedURLs)
    }
    
    func reloadEverything() async {
      try? await CurrentUserStore.shared.loadUser()
    seedFromCurrentUser()
        
    }
    

    func loadImage(at index: Int) {
        
        guard let selection = pickerItems[index] else {return}

        Task {
            guard let user =  CurrentUserStore.shared.user else {return}
            if let oldPath = imagePaths[index],
                let oldURLs = imageURLs[index]
                
                {
                try? await StorageManager.instance.deleteImage(path: oldPath)
                try? await ProfileManager.instance.removeImagePath(userId: user.userId , path: oldPath, url: oldURLs)
                
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
            let newPath = try await StorageManager.instance.saveImage(userId: user.userId, data: data)
            let newURL = try await StorageManager.instance.getUrlForImage(path: newPath)
            try await ProfileManager.instance.updateImagePath(userId: user.userId, path: newPath, url: newURL.absoluteString)
            try await CurrentUserStore.shared.loadUser()
            
            await MainActor.run {
                imagePaths[index] = newPath
                imageURLs[index] = newURL.absoluteString
                pickerItems[index] = nil
            }
        }
    }

}
