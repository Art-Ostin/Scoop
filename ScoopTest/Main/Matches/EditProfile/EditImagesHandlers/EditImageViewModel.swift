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
    var path: String?
    var url: URL?
}


@Observable class EditImageViewModel {
    
    var profileManager: ProfileManaging
    var storageManager: StorageManaging
    var user: CurrentUserStore
    
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    
    init (profileManager: ProfileManaging, storageManager: StorageManaging, user: CurrentUserStore) {
        self.profileManager = profileManager
        self.storageManager = storageManager
        self.user = user
    }
    
    @MainActor
    func assignSlots() {
        guard let user = user.user else { return }
        let paths = user.imagePath ?? []
        let urls = user.imagePathURL?.compactMap { URL(string: $0) } ?? []
        for i in slots.indices {
            slots[i].path =  i < paths.count ? paths[i] : nil
            slots[i].url = i < urls.count ? urls[i] : nil
        }
    }
    
    func changeImage(at index: Int) {
        Task {
            await MainActor.run { slots[index].url = nil}
            
            if let oldPath = slots[index].path, let oldURL = slots[index].url {
                try await storageManager.deleteImage(path: oldPath)
                try await profileManager.update(values: [
                    .imagePath: FieldValue.arrayRemove([oldPath]),
                    .imagePathURL: FieldValue.arrayRemove([oldURL.absoluteString])
                ]
                )
            }
            
            guard
                let selection = slots[index].pickerItem,
                let data = try? await selection.loadTransferable(type: Data.self) else {return}
                    
            do {
                let newPath = try await storageManager.saveImage(data: data)
                let newURL = try await storageManager.getImageURL(path: newPath)
                try await profileManager.update(values: [
                    .imagePath: FieldValue.arrayUnion([newPath]),
                    .imagePathURL: FieldValue.arrayUnion([newURL.absoluteString])
                ])
                await MainActor.run {
                    slots[index].path = newPath
                    slots[index].url = newURL
                    slots[index].pickerItem = nil
                }
                
            } catch {
                print(error)
            }
        }
    }
}
