//
//  EditProfileViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 19/08/2025.
//Structure: The data edits the 'draft' profile which is repeatedly updated to be displayed on the 'preview' 'view' screen. Images however depend on the images.

import Foundation
import SwiftUI

@MainActor
@Observable class EditProfileViewModel {

    @ObservationIgnored private let session: Session
    @ObservationIgnored private let storageService: StorageServicing
    @ObservationIgnored private let userRepo: UserRepository
    @ObservationIgnored let imageLoader: ImageLoading

    var draft: UserProfile
    var images: [UIImage] = Array(repeating: placeholder, count: 6) //The loaded photos in screen order; a drop reorders them

    var updatedFields: [UserProfile.Field : Any] = [:]
    var updatedImages: [Int: Data] = [:] //Replacements keyed by the photo's ORIGINAL slot, so each follows its photo through any reorder
    private(set) var photoOrder: [Int] = Array(0..<photoSlots) //photoOrder[slot] = the original slot of the photo shown there; also its grid id
    @ObservationIgnored private var importedGallery: [String] //The stored imagePathURL `images` were loaded from
    private(set) var didSave = false //A save leaves the edits above in place, so showSaveButton alone still reads true after one

    init(session: Session, storageService: StorageServicing, userRepo: UserRepository, imageLoader: ImageLoading,
         importedImages: [UIImage], importedGallery: [String]) {
        self.session = session
        self.storageService = storageService
        self.userRepo = userRepo
        self.imageLoader = imageLoader
        self.draft = session.user
        self.images = importedImages
        self.importedGallery = importedGallery
    }


    var user: UserProfile { session.user }

    var showSaveButton: Bool { !updatedFields.isEmpty || !updatedImages.isEmpty || hasReorderedPhotos }
    var hasUnsavedChanges: Bool { showSaveButton && !didSave } //Read by the presenter once the cover has closed

    func set<T: Equatable>(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, T>,  to value: T) {
        draft[keyPath: kp] = value
        if user[keyPath: kp] == value {
            updatedFields.removeValue(forKey: key)
        } else {
            updatedFields[key] = value
        }
    }

    func setPrompt(_ key: UserProfile.Field, _ kp: WritableKeyPath<UserProfile, PromptResponse>, to value: PromptResponse) {
        draft[keyPath: kp] = value
        updatedFields[key] = ["prompt": value.prompt, "response": value.response]
    }
    
    func setMeetupPreferences(_ value: MeetupPreferences) {
        draft.meetupPreferences = value
        updatedFields[.meetupPreferences] = value == user.meetupPreferences ? nil : [
            "preferredActivities": value.preferredActivities,
            "preferredDays": value.preferredDays,
            "dreamDate": value.dreamDate
        ]
    }
    

    func movePrompts(from source: IndexSet, to destination: Int) {
        var reordered = [draft.prompt1, draft.prompt2, draft.prompt3]
        reordered.move(fromOffsets: source, toOffset: destination)

        let keys: [UserProfile.Field] = [.prompt1, .prompt2, .prompt3]
        let paths: [WritableKeyPath<UserProfile, PromptResponse>] =
            [\.prompt1, \.prompt2, \.prompt3]

        for i in reordered.indices where reordered[i] != draft[keyPath: paths[i]] {
            setPrompt(keys[i], paths[i], to: reordered[i])
        }
    }

    //ONE write for everything pending: fields, the reordered gallery and fresh uploads land together or not at all
    func saveProfileChanges() async throws {
        //Captured before the first await: the listener rewrites session.user the moment the write lands locally
        let userId = user.id
        let stored = Self.storedPhotos(of: user)
        let isCurrent = galleryIsCurrent
        let order = photoOrder
        let replacements = updatedImages
        var values = updatedFields

        var replaced: [StoredPhoto] = []
        if order != Array(order.indices) || !replacements.isEmpty {
            //Moves made on photos that are no longer the stored ones (a stale seed, a second Save after the echo) must not land
            guard isCurrent else { throw GalleryChanged() }
            let uploadStart = Date() // ⏱
            let uploads = try await upload(replacements, userId: userId)
            print("⏱ uploads: \(replacements.count) photo(s) in parallel \(uploadStart.elapsed)") // ⏱
            var gallery: [StoredPhoto] = []
            for origin in order {
                let old = stored.indices.contains(origin) ? stored[origin] : nil
                if let fresh = uploads[origin] {
                    gallery.append(fresh)
                    if let old { replaced.append(old) }
                } else if let old {
                    gallery.append(old)
                }
            }
            gallery += stored.dropFirst(order.count) //Stored photos past the grid's six keep their place at the end
            values[.imagePath] = gallery.map(\.path)
            values[.imagePathURL] = gallery.map(\.url)
        }
        guard !values.isEmpty else { return }
        let writeStart = Date() // ⏱
        try await userRepo.updateUser(userId: userId, values: values)
        print("⏱ Firestore updateUser \(writeStart.elapsed)") // ⏱
        didSave = true
        let discarded = replaced
        Task { await discard(discarded) } //Only now does nothing point at them; cleanup never holds the dismiss
    }

    func interestIsSelected(text: String) -> Bool {
        user.interests.contains(text) == true
    }

    func updateUser(values: [UserProfile.Field : Any]) async throws  {
        try await userRepo.updateUser(userId: user.id, values: values)
    }
}

//Image Functionality
extension EditProfileViewModel {
    //Images
    static let placeholder = UIImage(named: "ImagePlaceholder") ?? UIImage()
    static let photoSlots = 6

    //One stored photo, in the loader's index space
    private struct StoredPhoto: Sendable {
        let path: String
        let url: String
    }

    private struct GalleryChanged: Error {}

    var hasReorderedPhotos: Bool { photoOrder != Array(photoOrder.indices) }

    //`images` show the stored gallery, not a seed loaded before the last save landed
    var galleryIsCurrent: Bool { importedGallery == user.imagePathURL }

    //Every stored photo must be on screen: a failed fetch shortens `images` and shifts each slot after it off its stored photo
    var canReorderPhotos: Bool {
        let stored = Self.storedPhotos(of: user).count
        return galleryIsCurrent && images.count == stored && stored <= Self.photoSlots
    }

    //A stale seed reloads from the stored gallery; until it lands, the grid neither lifts nor opens an editor
    func refreshImagesIfStale() async {
        while !galleryIsCurrent, !Task.isCancelled {
            guard updatedImages.isEmpty, !hasReorderedPhotos else { return } //Edits made against the old photos: Save refuses them
            let gallery = user.imagePathURL
            let loaded = await imageLoader.loadProfileImages(user)
            guard gallery == user.imagePathURL else { continue } //The gallery moved mid-load: load the newer one
            images = loaded
            importedGallery = gallery
        }
    }

    //Shift/insert: the photo leaves `from`, the ones between close up behind it. Replacements ride along (keyed by origin)
    func movePhoto(from: Int, to: Int) {
        guard canReorderPhotos, images.indices.contains(from), images.indices.contains(to) else { return }
        images.reorder(from: from, to: to)
        photoOrder.reorder(from: from, to: to)
    }

    //The editor hands back the slot it opened from; the replacement is filed under that photo's origin
    func changeImage(image: ImageSlot) {
        let slot = image.index
        guard photoOrder.indices.contains(slot) else { return }
        if images.indices.contains(slot) { images[slot] = image.image }
        let start = Date() // ⏱
        if let data = image.jpegData { updatedImages[photoOrder[slot]] = data }
        print("⏱ JPEG encode (main thread) \(start.elapsed) · \(image.image.cgImage?.width ?? 0)×\(image.image.cgImage?.height ?? 0) px · \((updatedImages[photoOrder[slot]]?.count ?? 0) / 1024) KB") // ⏱
    }

    //Mirrors ImageLoader.loadProfileImages' compactMap, so index i here is the i-th photo it loads
    private static func storedPhotos(of user: UserProfile) -> [StoredPhoto] {
        user.imagePathURL.enumerated().compactMap { i, url in
            guard URL(string: url) != nil else { return nil }
            return StoredPhoto(path: user.imagePath.indices.contains(i) ? user.imagePath[i] : "", url: url)
        }
    }

    //saveImage already returns the resized variant's path, so it is stored as-is
    private func upload(_ replacements: [Int: Data], userId: String) async throws -> [Int: StoredPhoto] {
        let storage = storageService
        return try await withThrowingTaskGroup(of: (Int, StoredPhoto).self) { group in
            for (origin, data) in replacements {
                group.addTask {
                    let saved = try await storage.saveImage(data: data, userId: userId)
                    return (origin, StoredPhoto(path: saved.path, url: saved.url.absoluteString))
                }
            }
            var uploads: [Int: StoredPhoto] = [:]
            for try await (origin, photo) in group { uploads[origin] = photo }
            return uploads
        }
    }

    //Best-effort: the saved profile no longer references these, so a failed delete only leaves an orphan
    private func discard(_ photos: [StoredPhoto]) async {
        for photo in photos {
            if let url = URL(string: photo.url) { await imageLoader.removeImage(for: url) }
            if !photo.path.isEmpty { try? await storageService.deleteImage(path: photo.path) }
        }
    }
}
