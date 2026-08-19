//
//  ProfileViewModel.swift
//  Scoop
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

    //Injected
    let profile: UserProfile
    let event: UserEvent?
    let imageLoader: ImageLoading
    let defaults: DefaultsManaging //Passed on for invites and maps (simplifies architecture for invite popups)

    //State
    var viewProfileType: ProfileViewType
    private(set) var images: [UIImage]
    private var hasLoaded = false

    init(profile: UserProfile, event: UserEvent? = nil, imageLoader: ImageLoading, defaults: DefaultsManaging, images: [UIImage] = []) {
        self.profile = profile
        self.imageLoader = imageLoader
        self.event = event
        self.defaults = defaults
        self.images = images
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
    
    func seed(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        self.images = images
    }

    func loadImagesIfNeeded() async {
        guard !hasLoaded, images.count <= 1 else { return }
        let loaded = await imageLoader.loadProfileImages(profile)
        guard !loaded.isEmpty else { return }
        images = loaded
        hasLoaded = true
    }
}





@Observable final class ProfileUIState {

    //Current page of the header image pager — Quick Invite opens on this image.
    var selectedImageIndex: Int = 0
    var showInvite: Bool = false

    //Set on the decline tap: the response cover's flying cross takes over from the button's icon
    var didDecline: Bool = false

    //The decline button's resting global frame — the launch pad the cover's cross leaps from
    var declineButtonFrame: CGRect = .zero
}
