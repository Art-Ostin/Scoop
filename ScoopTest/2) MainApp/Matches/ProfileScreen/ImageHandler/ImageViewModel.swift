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
      Task {
          if let existingPaths = await EditProfileViewModel.instance.user?.imagePath {
              let filled = existingPaths + Array(repeating: nil, count: max(0,6-existingPaths.count))
              await MainActor.run {
                imagePaths = Array(filled.prefix(6))
              }
          }
          if let existingURLs = await EditProfileViewModel.instance.user?.imagePathURL {
              let filledU = existingURLs + .init(repeating: nil, count: max(0,6-existingURLs.count))
              await MainActor.run { imageURLs = Array(filledU.prefix(6)) }
          }
      }
    }

    func loadImage(at index: Int) {
        guard let selection = pickerItems[index] else {return}

        Task {
            
            guard let user = await EditProfileViewModel.instance.user else {return}
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
            
            await MainActor.run {
                imagePaths[index] = newPath
                imageURLs[index] = newURL.absoluteString
                pickerItems[index] = nil
            }
        }
    }
    
    
    
}

/*
 func saveImage(at index: Int) {
 Task {
 if let data = try? await pickerItems[index]?.loadTransferable(type: Data.self) {
 guard let userId = await EditProfileViewModel.instance.user?.userId else {return}
 let path = try await StorageManager.instance.saveImage(userId: userId, data: data)
 let url = try await StorageManager.instance.getUrlForImage(path: path)
 try await ProfileManager.instance.updateImagePath(userId: userId, path: path, url: url.absoluteString)
 }
 }
 }
 */


/*
 func deleteImage(at index: Int) {
 
 Task {
 guard
 let user = await EditProfileViewModel.instance.user,
 let paths = user.imagePath,
 let urls = user.imagePathURL,
 index < paths.count,
 index < urls.count
 else {return}
 
 let oldPath = paths[index]
 let oldURL  = urls[index]
 
 try? await StorageManager.instance.deleteImage(path: oldPath)
 
 try? await ProfileManager.instance.removeImagePath(
 userId: user.userId,
 path: oldPath,
 url: oldURL
 )
 }
 }
 */
