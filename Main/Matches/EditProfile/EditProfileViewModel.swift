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
    
    var defaults: DefaultsManager
    var cacheManager: CacheManaging
    var userManager: UserManager
    var s: SessionManager
    var storageManager: StorageManaging
    var cycleManager: CycleManager
    var eventManager: EventManager
    
    
    
    
    var draftUser: UserProfile?
    
    init(cacheManager: CacheManaging, s: SessionManager, userManager: UserManager, storageManager: StorageManaging, cycleManager: CycleManager, eventManager: EventManager, draftUser: UserProfile? = nil, defaults: DefaultsManager) {
        self.cacheManager = cacheManager
        self.s = s
        self.userManager = userManager
        self.storageManager = storageManager
        self.draftUser = draftUser
        self.defaults = defaults
        self.cycleManager = cycleManager
        self.eventManager = eventManager
    }

    var user: UserProfile { s.user }
    
    var updatedFields: [UserProfile.Field : Any] = [:]
    
    func set<T>(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, T>,  to value: T) {
        guard var draftUser else {return}
        draftUser[keyPath: kp] = value
        updatedFields[key] = value
    }
    
    func setPrompt(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, PromptResponse?>, to value: PromptResponse) {
        guard var draftUser else {return}
        print(value)
        print(kp)
        draftUser[keyPath: kp] = value
        updatedFields[key] = ["prompt": value.prompt, "response": value.response]
    }
    
    func saveUser() async throws {
        guard !updatedFields.isEmpty else { return }
        try await userManager.updateUser(values: updatedFields)
    }
    
    var updatedFieldsArray: [(field: UserProfile.Field, value: String, add: Bool)] = []
    
    func setArray(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, [String]>,  to element: String, add: Bool) {
        guard var draftUser else {return}
        if add == true {
            draftUser[keyPath: kp].append(element)
        } else {
            draftUser[keyPath: kp].removeAll(where: {$0 == element})
        }
        updatedFieldsArray.append((field: key, value: element, add: add))
        print(updatedFieldsArray)        
    }
    
    func saveUserArray() async throws {
        guard !updatedFieldsArray.isEmpty else { return }
        for (field, value, add) in updatedFieldsArray {
            try await userManager.updateUserArray(field: field, value: value, add: add)
        }
    }
    
    //Images
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()
    var images: [UIImage] = Array(repeating: placeholder, count: 6)
    
    var isValid: Bool {
        images.allSatisfy { $0 !== EditProfileViewModel.placeholder}
    }
    
    @MainActor
    func assignSlots() async {
        let paths = user.imagePath
        let urlStrings = user.imagePathURL
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
    
    
    
    
    var updatedImages: [(index: Int, data: Data)] = []
    
    
    func saveUpdatedImages() async throws {
        let updates = updatedImages
        let snapshotSlots = slots
        var paths = user.imagePath
        var urls  = user.imagePathURL
        if paths.count < 6 { paths += Array(repeating: "", count: 6 - paths.count) }
        if urls.count  < 6 { urls  += Array(repeating: "", count: 6 - urls.count) }
        let userId = user.id
        
        struct ImgResult { let index: Int; let path: String; let url: URL }
        
        let results: [ImgResult] = try await withThrowingTaskGroup(of: ImgResult.self, returning: [ImgResult].self) { group in
            for (index, data) in updates {
                let oldPath = snapshotSlots[index].path
                let oldURL  = snapshotSlots[index].url
                
                group.addTask {
                    if let oldURL { await self.cacheManager.removeImage(for: oldURL) }
                    if let oldPath { try? await self.storageManager.deleteImage(path: oldPath) }
                    let originalPath = try await self.storageManager.saveImage(data: data, userId: userId)
                    let url = try await self.storageManager.getImageURL(path: originalPath)
                    let resized = originalPath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
                    return ImgResult(index: index, path: resized, url: url)
                }
            }
            var tmp: [ImgResult] = []
            for try await r in group { tmp.append(r) }
            return tmp
        }
        
        for r in results {
            paths[r.index] = r.path
            urls[r.index]  = r.url.absoluteString
        }
        try await userManager.updateUser(values: [.imagePath: paths, .imagePathURL: urls])
    }
    
    
    func changeImage(at index: Int, onboarding: Bool = false) async throws {
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
        else { return }

        await MainActor.run {
            if images.indices.contains(index) { images[index] = uiImage }
        }
        
        if let i = updatedImages.firstIndex(where: {$0.index == index}) {
            updatedImages[i] = (index: index, data: data)
        } else {
            updatedImages.append((index: index, data: data))
        }
        
        if onboarding {
            if let oldURL = slots[index].url { cacheManager.removeImage(for: oldURL) }
            if let oldPath = slots[index].path { try? await storageManager.deleteImage(path: oldPath)}
            

            if let draftProfile = defaults.fetch() {
                let id = draftProfile.id
                
                
                let originalPath = try await storageManager.saveImage(data: data, userId: id)
                let url = try await storageManager.getImageURL(path: originalPath)

                let resizedPath = originalPath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
                setDraftImage(at: index, path: resizedPath, url: url)
            }
        }
    }
    
    
    private func setDraftImage(at index: Int, path: String, url: URL) {
        var p = draftProfile?.imagePath ?? []
        var u = draftProfile?.imagePathURL ?? []
        if p.count < 6 { p += Array(repeating: "", count: 6 - p.count) }
        if u.count < 6 { u += Array(repeating: "", count: 6 - u.count) }
        
        p[index] = path
        u[index] = url.absoluteString
        
        saveDraft(_kp: \.imagePath, to: p)
        saveDraft(_kp: \.imagePathURL, to: u)
        
        if slots.indices.contains(index) {
            slots[index].path = path
            slots[index].url  = url
        }
    }
    
    
    func fetchUserField<T>(_ key: KeyPath<UserProfile, T>) -> T {
        user[keyPath: key]
    }
    
    func interestIsSelected(text: String) -> Bool {
        user.interests.contains(text) == true
    }
    
    func updateUser(values: [UserProfile.Field : Any]) async throws  {
        try await userManager.updateUser(values: values)
    }
    
    func updateUserArray(field: UserProfile.Field, value: String, add: Bool) async throws {
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
        guard let draftUser else {return}
        selectedCountries = draftUser.nationality
    }
    
    //Onboarding Functions
    var draftProfile: DraftProfile? { defaults.fetch() }
    
    
    func saveDraft<T>(_kp kp: WritableKeyPath<DraftProfile, T>, to value: T) {
        defaults.update(kp, to: value)
        print("saved")
    }
}
