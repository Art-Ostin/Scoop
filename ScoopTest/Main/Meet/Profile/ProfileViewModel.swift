//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/08/2025.
//
import Foundation
import SwiftUI

enum ProfileType {
    case sendInvite, receivedInvite, view
}

@Observable class ProfileViewModel {
    
    let cacheManager: CacheManaging
    var p: UserProfile
    var event: UserEvent?
    var profileType: ProfileType
    var showInvite: Bool = false
    
    init(profileInvite: ProfileInvite, profileType: ProfileType = .sendInvite, cacheManager: CacheManaging) {
        self.p = profileInvite.profile
        self.event = profileInvite.event
        self.profileType = profileType
        self.cacheManager = cacheManager
    }
    
    func loadImages() async -> [UIImage] {
        return await cacheManager.loadProfileImages([p])
    }
}
