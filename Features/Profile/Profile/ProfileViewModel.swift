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
    
    let profile: UserProfile
    let event: UserEvent?
    
    let imageLoader: ImageLoading
    let defaults: DefaultsManaging
    let s: SessionManager
        
    var viewProfileType: ProfileViewType
    
    init(defaults: DefaultsManaging, sessionManager: SessionManager, profile: UserProfile, event: UserEvent? = nil, imageLoader: ImageLoading) {
        self.profile = profile
        self.imageLoader = imageLoader
        self.defaults = defaults
        self.s = sessionManager
        self.event = event
        
        if event?.status == .pastAccepted || event?.status == .accepted {
            self.viewProfileType = .view
        } else if event?.status == .pending {
            self.viewProfileType = .accept
        } else {
            self.viewProfileType = .invite
        }
    }
    
    func loadImages() async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile)
    }
}
enum DragType {
    case details, profile, horizontal
}


@Observable final class ProfileUIState {
    var showInvitePopup = false
//    var showDeclineScreen = false
    var detailsOpen = false
    var dragType: DragType? = nil
    var isTopOfScroll = true
    var detailsOpenOffset: CGFloat = -284
    var hideProfileScreen: Bool = false
    let dismissalDuration: TimeInterval = 0.25
}





