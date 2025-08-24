//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

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
@Observable class EditProfileViewModel {
    
    var cacheManager: CacheManaging
    var userManager: UserManager
    var s: SessionManager
    var storageManager: StorageManaging
    
    var draftUser: UserProfile
    
    init(cacheManager: CacheManaging, s: SessionManager, userManager: UserManager, storageManager: StorageManaging, draftUser: UserProfile) {
        self.cacheManager = cacheManager
        self.s = s
        self.userManager = userManager
        self.storageManager = storageManager
        self.draftUser = draftUser
    }
    
    var user: UserProfile { s.user }
    
    
    var updatedFields: [UserProfile.CodingKeys : Any] = [:]
    
    func set<T>(_ key: UserProfile.CodingKeys, _ kp: WritableKeyPath<UserProfile, T>,  to value: T) {
        draftUser[keyPath: kp] = value
        updatedFields[key] = value
    }
    
    func setPrompt(_ key: UserProfile.CodingKeys, _ kp: WritableKeyPath<UserProfile, PromptResponse?>, to value: PromptResponse) {
        print(value)
        print(kp)
        draftUser[keyPath: kp] = value
        updatedFields[key] = ["prompt": value.prompt, "response": value.response]
    }
    
    func saveUser() async throws {
        guard !updatedFields.isEmpty else { return }
        try await userManager.updateUser(values: updatedFields)
        await s.loadUser()
    }
    

    var updatedFieldsArray: [(field: UserProfile.CodingKeys, value: String, add: Bool)] = []
    
    func setArray(_ key: UserProfile.CodingKeys, _ kp: WritableKeyPath<UserProfile, [String]?>,  to element: String, add: Bool) {
        if add == true {
            draftUser[keyPath: kp]?.append(element)
        } else {
            draftUser[keyPath: kp]?.removeAll(where: {$0 == element})
        }
        updatedFieldsArray.append((field: key, value: element, add: add))
        print(updatedFieldsArray)
    }
    
    func saveUserArray() async throws {
        guard !updatedFieldsArray.isEmpty else { return }
        for (field, value, add) in updatedFieldsArray {
            try await userManager.updateUserArray(field: field, value: value, add: add)
        }
        await s.loadUser()
    }
    
    
    
    //Images
    
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()
    var images: [UIImage] = Array(repeating: placeholder, count: 6)    
    
    var isValid: Bool {
        images.allSatisfy { $0 !== EditProfileViewModel.placeholder }
    }
    
    @MainActor
    func assignSlots() async {
        let paths = draftUser.imagePath ?? []
        let urlStrings = draftUser.imagePathURL ?? []
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
        print("slots assigned")
    }
    
    var updatedImages: [(index: Int, data: Data)] = []
    
    func saveUpdatedImages () async throws {
        for (index, data) in updatedImages {
           try await updateImage(index: index, data: data)
        }
    }
    
    func loadUser() async {
       await s.loadUser()
    }
    
    
    func updateImage(index: Int, data: Data) async throws {
        
        if let oldPath = slots[index].path, let oldURL = slots[index].url {
            cacheManager.removeImage(for: oldURL)
            try await storageManager.deleteImage(path: oldPath)
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
        print("Updated image called")
    }
    
    
    func changeImage(at index: Int) async throws {
        
        print("change image called")
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
        else { return }
        
        await MainActor.run {
            if images.indices.contains(index) { images[index] = uiImage } else {
                print("error did not contain")
            }
        }
        
        if let i = updatedImages.firstIndex(where: {$0.index == index}) {
            updatedImages[i] = (index: index, data: data)
            
            
        } else {
            updatedImages.append((index: index, data: data))
        }
        print(updatedImages)
    }


    func fetchUserField<T>(_ key: KeyPath<UserProfile, T>) -> T {
        user[keyPath: key]
    }
    
    func interestIsSelected(text: String) -> Bool {
        user.interests?.contains(text) == true
    }

    func updateUser(values: [UserProfile.CodingKeys : Any]) async throws  {
        try await userManager.updateUser(values: values)
    }
    
    func updateUserArray(field: UserProfile.CodingKeys, value: String, add: Bool) async throws {
        try await userManager.updateUserArray(field: field, value: value, add: add)
    }
    
    
    
    
    //Nationality Functionality
    var selectedCountries: [String] = []
    let countries = CountryDataServices.shared.allCountries
    var availableLetters: Set<String> {
        Set(countries.map { String($0.name.prefix(1)) })
    }
    
    var groupedCountries: [(letter: String, countries: [CountryData])] {
        let groups = Dictionary(grouping: countries, by: { String($0.name.prefix(1)) })
        let sortedKeys = groups.keys.sorted()
        return sortedKeys.map { key in
            (key, groups[key]!.sorted { $0.name < $1.name })
        }
    }
    
    func isSelected(_ country: String) -> Bool {
        selectedCountries.contains(country)
    }
    
    func toggleCountry(_ country: String) {
        if selectedCountries.contains(country) {
            selectedCountries.removeAll(where: {$0 == country})
            setArray(.nationality, \.nationality, to: country, add: false)
        } else if selectedCountries.count < 3 {
            selectedCountries.append(country)
            setArray(.nationality, \.nationality, to: country, add: true)
        }
    }

    func fetchNationality() {
        selectedCountries = draftUser.nationality ?? []
    }
}
