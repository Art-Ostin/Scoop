//
//  ProfileModelBuilder.swift
//  Scoop
//
//  Created by Art Ostin on 03/09/2025.
//

import Foundation


final class ProfileModelBuilder {
    private let userManager: UserManager
    private let cache: CacheManaging
    
    init(userManager: UserManager, cache: CacheManaging) {
        self.userManager = userManager
        self.cache = cache
    }
    
    @discardableResult
    private func prewarmCache(for profiles: [UserProfile]) -> Task<Void, Never>? {
        guard !profiles.isEmpty else { return nil }
        return Task.detached(priority: .utility) { [cache] in
            await cache.loadProfileImages(profiles)
        }
    }
    
    func fromEvents(_ events: [UserEvent]) async throws -> [ProfileModel] {
        var models: [ProfileModel] = []
        try await withThrowingTaskGroup(of: ProfileModel?.self) {group in
            for event in events {
                group.addTask {
                    guard let profile = try? await self.userManager.fetchProfile(userId: event.otherUserId) else { return nil }
                    let img = try? await self.cache.fetchFirstImage(profile: profile)
                    return ProfileModel(event: event, profile: profile, image: img)
                }
            }
            for try await m in group { if let m { models.append(m)} }
        }
        prewarmCache(for: models.map(\.profile))
        return models
    }
    
    func fromIds(_ ids: [String]) async throws -> [ProfileModel] {
        var models: [ProfileModel] = []
        try await withThrowingTaskGroup(of: ProfileModel?.self) {group in
            for id in ids {
                group.addTask {
                    guard let profile = try? await self.userManager.fetchProfile(userId: id) else { return nil }
                    let img = try? await self.cache.fetchFirstImage(profile: profile)
                    return ProfileModel(event: nil, profile: profile, image: img)
                }
            }
            for try await m in group { if let m { models.append(m)} }
        }
        prewarmCache(for: models.map(\.profile))
        return models
    }
    
    func fromEvent(_ event: UserEvent) async throws -> ProfileModel {
        let profile = try await userManager.fetchProfile(userId: event.otherUserId)
        let img = try? await cache.fetchFirstImage(profile: profile)
        prewarmCache(for: [profile])
        return ProfileModel(event: event, profile: profile, image: img)
    }
    
    func fromId(_ id: String) async throws -> ProfileModel {
        let profile = try await userManager.fetchProfile(userId: id)
        let img = try? await cache.fetchFirstImage(profile: profile)
        prewarmCache(for: [profile])
        return ProfileModel(event: nil, profile: profile, image: img)
    }
}
