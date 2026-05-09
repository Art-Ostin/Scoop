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
    var showPopup: Bool = false
    var isAtTopOfScroll = true
    var selectedDetent: PresentationDetent = .fraction(0.26)

    // Live geometry of the native sheet, in global coords. Updated continuously
    // while the user drags so the parallel card overlay can mirror the sheet
    // without lag.
    var sheetTopY: CGFloat = 0
    var sheetHeight: CGFloat = 0

    let dismissDuration = 0.25

    // Detent fractions used to interpolate the parallel card's width and
    // corner radius. Kept here so the sheet config and the overlay agree.
    let smallDetent: CGFloat = 0.26
    let largeDetent: CGFloat = 0.62
    
    var detailOpen: Bool {
        selectedDetent == .fraction(largeDetent)
    }

    func isAtLargeDetent(screenHeight: CGFloat) -> Bool {
        abs(sheetTopY - screenHeight * (1 - largeDetent)) < 0.5
    }
}
