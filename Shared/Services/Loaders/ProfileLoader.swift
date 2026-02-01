//
//  ProfileModelBuilder.swift
//  Scoop
//
//  Created by Art Ostin on 03/09/2025.
//

import Foundation


final class ProfileLoader: ProfileLoading {
    
    private let userRepo: UserRepository
    private let imageLoader: ImageLoading
    
    init(userRepo: UserRepository, imageLoader: ImageLoading) {
        self.userRepo = userRepo
        self.imageLoader = imageLoader
    }
    
    func fromEvents(_ events: [UserEvent]) async throws -> [ProfileModel] {
        var models: [ProfileModel] = []
        try await withThrowingTaskGroup(of: ProfileModel?.self) {group in
            for event in events {
                group.addTask {
                    guard let profile = try? await self.userRepo.fetchProfile(userId: event.otherUserId) else { return nil }
                    let img = try? await self.imageLoader.fetchFirstImage(profile: profile)
                    return ProfileModel(event: event, profile: profile, image: img)
                }
            }
            for try await m in group { if let m { models.append(m)} }
        }
        imageLoader.addProfileImagesToCache(for: models.map(\.profile))
        return models
    }
    
    func fromIds(_ ids: [String]) async throws -> [ProfileModel] {
        var models: [ProfileModel] = []
        try await withThrowingTaskGroup(of: ProfileModel?.self) {group in
            for id in ids {
                group.addTask {
                    guard let profile = try? await self.userRepo.fetchProfile(userId: id) else { return nil }
                    let img = try? await self.imageLoader.fetchFirstImage(profile: profile)
                    return ProfileModel(event: nil, profile: profile, image: img)
                }
            }
            for try await m in group { if let m { models.append(m)} }
        }
        imageLoader.addProfileImagesToCache(for: models.map(\.profile)) //Check if this is working and images are getting added to Cache
        return models
    }
    
    func fromEvent(_ event: UserEvent) async throws -> ProfileModel {
        let profile = try await userRepo.fetchProfile(userId: event.otherUserId)
        let img = try? await imageLoader.fetchFirstImage(profile: profile)
        imageLoader.addProfileImagesToCache(for: [profile])
        return ProfileModel(event: event, profile: profile, image: img)
    }
    
    func fromId(_ id: String) async throws -> ProfileModel {
        let profile = try await userRepo.fetchProfile(userId: id)
        let img = try? await imageLoader.fetchFirstImage(profile: profile)
        imageLoader.addProfileImagesToCache(for: [profile])
        return ProfileModel(event: nil, profile: profile, image: img)
    }
}
