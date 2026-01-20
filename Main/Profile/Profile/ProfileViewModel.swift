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
    
    var transitionType: DismissTransition = .standard
    
    var dismissTransition: AnyTransition {
        switch transitionType {
        case .standard:
                .move(edge: .bottom)
        case .actionPerformed:
                .opacity
        }
    }
    
    var viewProfileType: ProfileViewType {
        if profileModel.event?.status == .pastAccepted || profileModel.event?.status == .accepted {
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

enum DismissTransition {
    case standard, actionPerformed
}

@Observable final class ProfileUIState {
    var showInvitePopup = false
    var showDeclineScreen = false
    var detailsOpen = false
    var dragType: DragType? = nil
    var isTopOfScroll = true
    var detailsOpenOffset: CGFloat = -284
    var hideProfileScreen: Bool = false
    let dismissalDuration: TimeInterval = 0.35
}




/*
 */
