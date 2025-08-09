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
            try await dep.storageManager.deleteImage(path: oldPath)
            
        }
        
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
        else { return }
        
        await MainActor.run {
            if images.indices.contains(index) { images[index] = uiImage }
        }
        
        let originalPath = try await dep.storageManager.saveImage(data: data)
        let url = try await dep.storageManager.getImageURL(path: originalPath)
        let resizedPath = originalPath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
        
        var paths = dep.userManager.user?.imagePath ?? []
        var urls  = dep.userManager.user?.imagePathURL ?? []
        if paths.count < 6 { paths.append(contentsOf: Array(repeating: "", count: 6 - paths.count)) }
        if urls.count  < 6 { urls.append(contentsOf:  Array(repeating: "", count: 6 - urls.count)) }
        
        
        paths[index] = resizedPath
        urls[index]  = url.absoluteString
        
        try await dep.profileManager.update(values: [
            .imagePath: paths,
            .imagePathURL: urls
        ])
        
        
        do {
            try await dep.userManager.loadUser()
            print("loaded User")
        } catch {
            print("Error")
        }
        await MainActor.run {
            slots[index].path = resizedPath
            slots[index].url = url
            slots[index].pickerItem = nil
        }
    }
}

