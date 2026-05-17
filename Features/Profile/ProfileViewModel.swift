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


@Observable final class ProfileUIState {
    
    //1. Logic dealing with disabling details offset view.
    var isAtTopOfScroll = true
    var detailsOpen: Bool = false
    
    var detailsDragEnabled: Bool {
        return true
    }
    
    //2. Logic dealing with positioning detailsCard on Screen
    var imageBottom: CGFloat = 0
    var hasUpdatedImageBottom = false

    //3. Logic with what screen showing
    var showPopup: Bool = false
    
    //4. Logic with opening and closing details
    var detailsOffset: CGFloat = 0
    let detailsOpenOffset: CGFloat = -240
    let detailsClosedOffset: CGFloat = 0

    //5. Dismiss animation
    let dismissDuration: Double = 0.25
}

