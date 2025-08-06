//
//  ImageViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.


import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

struct ImageSlot {
    var pickerItem: PhotosPickerItem?
    var image: UIImage?
    var path: String?
    var url: String?
}


@Observable class EditImageViewModel {
    
    var dep: AppDependencies
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    
    init (dep: AppDependencies) {
        self.dep = dep
    }
    
    func seedFromCurrentUser() {
        guard let user = dep.userStore.user else { return }
        let paths = user.imagePath ?? []
        let urls = user.imagePathURL ?? []
        for i in slots.indices {
            slots[i].path = i < paths.count ? paths[i] : nil
            slots[i].url = i < urls.count ? urls[i] : nil
        }
    }
    
    func changeImage(at index: Int) {
        Task {
            if let oldPath = slots[index].path, let oldURL = slots[index].url {
                try await dep.storageManager.deleteImage(path: oldPath)
                try await dep.profileManager.update(values: [
                    .imagePath: FieldValue.arrayRemove([oldPath]),
                    .imagePathURL: FieldValue.arrayRemove([oldURL])
                ]
                )
            }

            guard
                let selection = slots[index].pickerItem,
                let data = try? await selection.loadTransferable(type: Data.self),
                let image = UIImage(data: data) else {return}
            
            do {
                let newPath = try await dep.storageManager.saveImage(data: data)
                let newURL = try await dep.storageManager.getImageURL(path: newPath)
                try await dep.profileManager.update(values: [
                    .imagePath: FieldValue.arrayUnion([newPath]),
                    .imagePathURL: FieldValue.arrayUnion([newURL.absoluteString]),
                ])
                await MainActor.run {slots[index].image = image}
            } catch {
                print(error)
            }
        }
    }
}
