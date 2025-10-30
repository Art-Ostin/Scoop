//
//  LimitedAccessViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2025.
//

import SwiftUI
import FirebaseAuth

@Observable class OnboardingViewModel {
    
    @ObservationIgnored private let authManager: AuthManaging
    @ObservationIgnored private let defaultManager: DefaultsManager
    @ObservationIgnored private let sessionManager: SessionManager
    @ObservationIgnored private let userManager: UserManager
    @ObservationIgnored private let cacheManager: CacheManaging
    @ObservationIgnored private let storageManager: StorageManaging
    
    
    init(authManager: AuthManaging, defaultManager: DefaultsManager, sessionManager: SessionManager, userManager: UserManager, cacheManager: CacheManaging, storageManager: StorageManaging, slots: [ImageSlot], images: [UIImage]) {
        self.authManager = authManager
        self.defaultManager = defaultManager
        self.sessionManager = sessionManager
        self.userManager = userManager
        self.cacheManager = cacheManager
        self.storageManager = storageManager
        self.slots = slots
        self.images = images
    }

    func signOut() async throws {
        try await authManager.deleteAuthUser()
        defaultManager.deleteDefaults()
    }
    
    func fetchUser() async throws -> User? {
        await authManager.fetchAuthUser()
    }
    
    enum BootStrap { case needsLogin, ok}
    
    func bootstrap() async -> BootStrap {
        guard let user = await authManager.fetchAuthUser() else { return .needsLogin }
        if defaultManager.signUpDraft == nil {
            defaultManager.deleteDefaults()
            defaultManager.signUpDraft = .init(user: user)
        }
        return .ok
    }
    
    var onboardingStep: Int {
        defaultManager.onboardingStep
    }
    
    func saveOnboardingDraft<T>(_kp kp: WritableKeyPath<DraftProfile, T>, to value: T) {
        defaultManager.update(kp, to: value)
        print("saved")
    }
    
    func createProfile() async throws {
        guard let signUpDraft = defaultManager.signUpDraft else {
            print("No draft")
            return
        }
        let profile = try userManager.createUser(draft: signUpDraft)
        await sessionManager.startSession(user: profile)
    }
    
    //I need to put the images into their own viewModel for the onboarding
    private func setDraftImage(at index: Int, path: String, url: URL) {
        guard let draft = defaultManager.signUpDraft else { return }
        var p = draft.imagePath
        var u = draft.imagePathURL
        if p.count < 6 { p += Array(repeating: "", count: 6 - p.count) }
        if u.count < 6 { u += Array(repeating: "", count: 6 - u.count) }
        
        p[index] = path
        u[index] = url.absoluteString
        saveOnboardingDraft(_kp: \.imagePath, to: p)
        saveOnboardingDraft(_kp: \.imagePathURL, to: u)
        
        if slots.indices.contains(index) {
            slots[index].path = path
            slots[index].url  = url
        }
    }
    
    var slots: [ImageSlot] = Array(repeating: .init(), count: 6)
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()
    var images: [UIImage] = Array(repeating: placeholder, count: 6)
    
    func changeImage(at index: Int) async throws {
        guard
            let selection = slots[index].pickerItem,
            let data = try? await selection.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
        else { return }
        
        await MainActor.run {
            if images.indices.contains(index) { images[index] = uiImage }
        }
        
        if let oldURL = slots[index].url { cacheManager.removeImage(for: oldURL) }
        if let oldPath = slots[index].path { try? await storageManager.deleteImage(path: oldPath)}
        
        if let draftProfile = defaultManager.signUpDraft {
            let id = draftProfile.id
            
            let originalPath = try await storageManager.saveImage(data: data, userId: id)
            let url = try await storageManager.getImageURL(path: originalPath)
            
            let resizedPath = originalPath.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
            setDraftImage(at: index, path: resizedPath, url: url)
        }
    }
}
