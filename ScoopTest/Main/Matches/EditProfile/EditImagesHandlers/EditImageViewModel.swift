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

    
    func loadUpImages() async {
        if let user = dep.userManager.user {
          let loaded = await dep.cacheManager.loadProfileImages([user])
            await MainActor.run {
                let count = min(loaded.count, 6)
                images.replaceSubrange(0..<count, with: loaded.prefix(count))
                if count < 6 {
                    images.replaceSubrange(count..<6, with: Array(repeating: UIImage(), count: 6 - count))
                }
            }
        }
    }


    func changeImage(at index: Int) async throws {
        if let oldPath = slots[index].path, let oldURL = slots[index].url {
            async let delete: () = dep.storageManager.deleteImage(path: oldPath)
            async let remove: () = dep.profileManager.update(values: [
                .imagePath: FieldValue.arrayRemove([oldPath]),
                .imagePathURL: FieldValue.arrayRemove([oldURL.absoluteString])
            ]
            )
            _ = try await (delete, remove)
            print("deleted Old Path")
        }
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self) else {return}
        
        let newPath = try await dep.storageManager.saveImage(data: data)
        print("New Path Generated")
        let newURL = try await dep.storageManager.getImageURL(path: newPath)
        print("New URL Generated")

        async let updateProfile: () = dep.profileManager.update(values: [
            .imagePath: FieldValue.arrayUnion([newPath]),
            .imagePathURL: FieldValue.arrayUnion([newURL.absoluteString])
        ])
        try await updateProfile
        print("profile Updated")
        
        let newImage = try await dep.cacheManager.fetchImage(for: newURL)
        
        await MainActor.run {
                guard images.indices.contains(index) else { return }
                images[index] = newImage                    // <- update where the UI reads
                slots[index].path = newPath
                slots[index].url = newURL
                slots[index].pickerItem = nil
            }
    }
}
