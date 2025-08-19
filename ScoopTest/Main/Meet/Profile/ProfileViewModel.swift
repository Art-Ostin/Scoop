//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/08/2025.
//
import Foundation
import SwiftUI


enum ProfileViewType {
    case invite, accept, view
}


@Observable class ProfileViewModel {
    
    let cacheManager: CacheManaging
    let userManager: UserManager
    let profileModel: ProfileModel
    
    var showInvitePopup: Bool = false
    var viewProfileType: ProfileViewType {
        if profileModel.profile == userManager.user || profileModel.event?.status == .accepted {
            return .view
        } else if profileModel.event?.status == .pending {
            return .accept
        } else {
            return .invite
        }
    }
    
    init(profileModel: ProfileModel, cacheManager: CacheManaging, userManager: UserManager) {
        self.profileModel = profileModel
        self.cacheManager = cacheManager
        self.userManager = userManager
    }
    
    func loadImages() async -> [UIImage] {
        return await cacheManager.loadProfileImages([profileModel.profile])
    }
}
