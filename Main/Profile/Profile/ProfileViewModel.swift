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

@MainActor
@Observable class ProfileViewModel {
    
    let profileModel: ProfileModel
    let cacheManager: CacheManaging
    
    var receivedEvent: UserEvent? { profileModel.event}
    
    var viewProfileType: ProfileViewType {
        if profileModel.event?.status == .accepted {
            return .view
        } else if profileModel.event?.status == .pending {
            return .accept
        } else {
            return .invite
        }
    }
    
    init(profileModel: ProfileModel, cacheManager: CacheManaging) {
        self.profileModel = profileModel
        self.cacheManager = cacheManager
    }
    
    func loadImages() async -> [UIImage] {
        return await cacheManager.loadProfileImages([profileModel.profile])
    }
}
enum DragType {
    case details, profile, horizontal
}


/*
 */
