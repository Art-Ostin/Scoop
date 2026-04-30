//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/08/2025.
//
import Foundation
import SwiftUI


enum ProfileViewType {
    case invite, accept, accepted, view
}

@MainActor
@Observable class ProfileViewModel {
    
    let profile: UserProfile
    let event: UserEvent?
    
    let imageLoader: ImageLoading
    let defaults: DefaultsManaging
    let s: SessionManager
        
    var viewProfileType: ProfileViewType
    
    init(defaults: DefaultsManaging, s: SessionManager, profile: UserProfile, event: UserEvent? = nil, imageLoader: ImageLoading) {
        self.profile = profile
        self.s = s
        self.imageLoader = imageLoader
        self.defaults = defaults
        self.event = event
        self.viewProfileType = Self.loadProfileViewType(event: event)
    }
    
    var userId: String {
        s.user.id
    }
    
    
    private static func loadProfileViewType(event: UserEvent? = nil) -> ProfileViewType {
        if event?.status == .pastAccepted {
            return .view
        } else if event?.status == .accepted {
            return .accepted
        } else if event?.status == .pending {
            return .accept
        } else {
            return .invite
        }
    }
    
    func loadImages() async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile)
    }
}

enum DragType {
    case details, horizontal
}


@Observable final class ProfileUIState {
    var showRespondPopup: Bool = false
    var showInfoSheet: Bool = false
    var detailsOpen = false
    var dragType: DragType? = nil
    var isTopOfScroll = true
    var showTimePopup = false
    var detailsOpenOffset: CGFloat = -284
    var hideProfileScreen: Bool = false
    var inviteTabSelection: Int = 0
}





