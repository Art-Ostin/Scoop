//
//  ImageViewModel.swift
//  ScoopTest

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

struct ImageSlot: Equatable {
    var pickerItem: PhotosPickerItem?
    var path: String?
    var url: URL?
}

@MainActor
@Observable class EditImageViewModel {
    
    var s: SessionManager
    var userManager: UserManager
    var cacheManager: CacheManaging
    var storageManager: StorageManaging
    
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()
    var images: [UIImage] = Array(repeating: placeholder, count: 6)
    

    init(s: SessionManager,userManager: UserManager, cacheManager: CacheManaging, storageManager: StorageManaging) {
        self.s = s
        self.userManager = userManager
        self.cacheManager = cacheManager
        self.storageManager = storageManager
    }
    
    var user: UserProfile {s.user}
    
    var isValid: Bool {
        images.allSatisfy { $0 !== EditImageViewModel.placeholder }
    }

        
    @MainActor
    func assignSlots() async {
        let paths = user.imagePath ?? []
        let urlStrings = user.imagePathURL ?? []
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
        
        if let oldPath = slots[index].path, let oldURL = slots[index].url {
            cacheManager.removeImage(for: oldURL)
            try await storageManager.deleteImage(path: oldPath)
        }
        
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
        else { return }
        
        await MainActor.run {
            if images.indices.contains(index) { images[index] = uiImage }
        }
        
        let originalPath = try await storageManager.saveImage(data: data, userId: user.userId)
        let url = try await storageManager.getImageURL(path: originalPath)
        let resizedPath = originalPath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
        
        var paths = user.imagePath ?? []
        var urls  = user.imagePathURL ?? []
        if paths.count < 6 { paths.append(contentsOf: Array(repeating: "", count: 6 - paths.count)) }
        if urls.count  < 6 { urls.append(contentsOf:  Array(repeating: "", count: 6 - urls.count)) }
        
        
        paths[index] = resizedPath
        urls[index]  = url.absoluteString
        
        try await userManager.updateUser(values: [
            .imagePath: paths,
            .imagePathURL: urls
        ])
        await s.loadUser()
        
        await MainActor.run {
            slots[index].path = resizedPath
            slots[index].url = url
            slots[index].pickerItem = nil
        }
    }
}

