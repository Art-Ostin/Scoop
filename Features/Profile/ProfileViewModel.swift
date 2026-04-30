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
    var viewProfileType: ProfileViewType
    
    init(profile: UserProfile, event: UserEvent? = nil, imageLoader: ImageLoading) {
        self.profile = profile
        self.imageLoader = imageLoader
        self.event = event
        self.viewProfileType = Self.loadProfileViewType(event: event)
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
    case details, profile, horizontal
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
    let dismissalDuration: TimeInterval = 0.25
    var inviteTabSelection: Int = 0
}



/*
 //    var userId: String {
 //        s.user.id
 //    }

 */
