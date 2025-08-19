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
    
    var firstImage: UIImage?
    
    var showInvite: Bool = false
    
    init(profile: UserProfile, profileType: ProfileType = .sendInvite, event: UserEvent? = nil, cacheManager: CacheManaging) {
        self.p = profile
        self.profileType = profileType
        self.event = event
        self.cacheManager = cacheManager
    }
    
    func loadImages() async -> [UIImage] {
        let image = await cacheManager.loadProfileImages([p])
        firstImage = image.first
        return image
    }
}
