//
//  ImageViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
// Explained: Assigns a data type "slot" to each image, which has its path, and Url for each image. Accordingly, when you change every image update on the backend and the front end, but also you need to change the slots its assigned to.


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
        for i in 0..<6 {
            slots[i].path = i < paths.count ? paths[i] : nil
            slots[i].url  = i < urls.count  ? urls[i]  : nil
            slots[i].pickerItem = nil
        }
        images = newImages
    }
    
    func changeImage(at index: Int) async throws {

        //Delete old Images at index
        if let oldPath = slots[index].path, let oldURL = slots[index].url {
            dep.cacheManager.removeImage(for: oldURL)
            async let delete: () = dep.storageManager.deleteImage(path: oldPath)
            async let remove: () = dep.profileManager.update(values: [
                .imagePath: FieldValue.arrayRemove([oldPath]),
                .imagePathURL: FieldValue.arrayRemove([oldURL.absoluteString])]
            )
            _ = try await (delete, remove)
        }
        
        //Immedietely update UI
        guard let selection = slots[index].pickerItem, let data = try? await selection.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) else { return }
        await MainActor.run { guard images.indices.contains(index) else { return }
            images[index] = uiImage
        }
        
        //get/save new paths to User (Firebase)
        let imagePath = try await dep.storageManager.saveImage(data: data)
        let url = try await dep.storageManager.getImageURL(path: imagePath)
        let updatedImagePath = imagePath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
        
        async let updateProfile: () = dep.profileManager.update(values: [
            .imagePath: FieldValue.arrayUnion([updatedImagePath]),
            .imagePathURL: FieldValue.arrayUnion([url.absoluteString])
        ])
        
        //Update User and UI
        try await updateProfile
        try await dep.userManager.loadUser()

        await MainActor.run {
            guard images.indices.contains(index) else { return }
            slots[index].path = updatedImagePath
            slots[index].url = url
            slots[index].pickerItem = nil
        }
    }
}
