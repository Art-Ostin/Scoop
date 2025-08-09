//
//  ImageViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.


import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

struct ImageSlot: Equatable {
    var pickerItem: PhotosPickerItem?
    var path: String?
    var url: URL?
}


@Observable class EditImageViewModel {
    
    var dep: AppDependencies
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()
    var images: [UIImage] = Array(repeating: placeholder, count: 6)
    
    init(dep: AppDependencies) { self.dep = dep }
    

    @MainActor
    func assignSlots() async {
        guard let user = dep.userManager.user else { return }
        let paths = user.imagePath ?? []
        let urlStrings = user.imagePathURL ?? []
        let urls = urlStrings.compactMap(URL.init(string:))
        var newImages = Array(repeating: Self.placeholder, count: 6)
        for i in 0..<min(urls.count, 6) {
            if let img = try? await dep.cacheManager.fetchImage(for: urls[i]) {
                newImages[i] = img
            }
        }
        print("assigned images ")
        await MainActor.run {
            for i in 0..<6 {
                slots[i].path = i < paths.count ? paths[i] : nil
                slots[i].url  = i < urls.count  ? urls[i]  : nil
                slots[i].pickerItem = nil
            }
            images = newImages
        }
    }
    
    
    func changeImage(at index: Int) async throws {

        //If there's already a image at that index, it will Delete it first in storage manager and the User's Path
        if let oldPath = slots[index].path, let oldURL = slots[index].url {
            print("old Paths have containers")
            async let delete: () = dep.storageManager.deleteImage(path: oldPath)
            async let remove: () = dep.profileManager.update(values: [
                .imagePath: FieldValue.arrayRemove([oldPath]),
                .imagePathURL: FieldValue.arrayRemove([oldURL.absoluteString])
            ]
            )
            _ = try await (delete, remove)
            print("deleted Old Path")
            dep.cacheManager.deleteImageFromCache(for: oldURL)
            
            
        } else {
            print("Cannot locate images at slot")
        }
        
        //Immedietely take the new selected Image, convert it to a UIImage, and update it onto the UI
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
        else { return print("Error not found and returned")}
        await MainActor.run {
            guard images.indices.contains(index) else { return }
            images[index] = uiImage
        }
        
        
        //Save the Image to StorageManager and make it a URL pointing to the NewImage (as old one is deleted automatically)
        let imagePath = try await dep.storageManager.saveImage(data: data)
        let url = try await dep.storageManager.getImageURL(path: imagePath)
        print("fetched URL and Image Path")
        
        
        //Update the imagePath so it now references the newImage (not the one saved) (This updating is done within the URL function)
        let updatedImagePath = imagePath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
        print("New Path Generated")
        
        
        //Updated the values in the user's profile to point to the new ImagePath (for path and URL)
        async let updateProfile: () = dep.profileManager.update(values: [
            .imagePath: FieldValue.arrayUnion([updatedImagePath]),
            .imagePathURL: FieldValue.arrayUnion([url.absoluteString])
        ])
        try await updateProfile
        print("profile Updated and URLs added")
        
        
        await MainActor.run {
            guard images.indices.contains(index) else { return }
            slots[index].path = updatedImagePath
            slots[index].url = url
            slots[index].pickerItem = nil
        }
        
        //Add the user's Image to the Cache
        let _ = try await dep.cacheManager.fetchImage(for: url)
        print("reloaded cache with new Image")
    }
}
