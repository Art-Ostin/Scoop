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
    let defaults: DefaultsManaging //Profile View Passes on defaults manager for invites, and maps (simplifies architecture for invite popups)
    
    var viewProfileType: ProfileViewType
    
    init(profile: UserProfile, event: UserEvent? = nil, imageLoader: ImageLoading, defaults: DefaultsManaging) {
        self.profile = profile
        self.imageLoader = imageLoader
        self.event = event
        self.defaults = defaults
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
    
    //1. Controls how high details is when open
    var detailsOpenOffset: CGFloat = -284
    
    //2.Different profile States
    var detailsOpen = false
    var showPopup: Bool = false
    
    
    let dismissalDuration: TimeInterval = 0.25
}


