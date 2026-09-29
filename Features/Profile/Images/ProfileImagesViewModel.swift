//
//  ProfileImagesViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 29/10/2025.
//

import UIKit

@MainActor
@Observable final class ProfileImagesViewModel {

    private let defaults: DefaultsManaging
    private let storageService: StorageServicing

    init(defaults: DefaultsManaging, storageService: StorageServicing) {
        self.defaults = defaults
        self.storageService = storageService
    }

    private struct NoSignUpDraft: Error {}

    //Screen order in, gallery order out: the first photo is the main one. The draft's id IS the auth uid, so no auth round trip
    func saveAll(images: [UIImage]) async throws {
        guard let userId = defaults.signUpDraft?.id else { throw NoSignUpDraft() }
        let storage = storageService
        let results = await withTaskGroup(of: Result<(Int, String, URL), Error>.self) { group in
            for (i, image) in images.enumerated() {
                group.addTask {
                    do { let photo = try await storage.saveImage(image, userId: userId); return .success((i, photo.path, photo.url)) }
                    catch { return .failure(error) }
                }
            }
            var all: [Result<(Int, String, URL), Error>] = []
            for await result in group { all.append(result) }
            return all
        }
        let saved = results.compactMap { try? $0.get() }.sorted { $0.0 < $1.0 }
        for case .failure(let error) in results { //One failed: the others' objects would never be referenced, so they go, off the critical path
            Task { for photo in saved { try? await storage.deleteImage(path: photo.1) } }
            throw error
        }
        defaults.mutateSignUpDraft { draft in
            draft.imagePath = saved.map { $0.1 }
            draft.imagePathURL = saved.map { $0.2.absoluteString }
        }
    }
}
