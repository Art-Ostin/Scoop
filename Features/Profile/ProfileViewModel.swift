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

    //Current page of the header image pager — the invite card zooms up from this image.
    var selectedImageIndex: Int = 0

    //Reverse-zoom close geometry (read by ZoomDismissRender). The drag system is
    //retired — these stay at rest and only the morph's closeProgress animates.
    var profileOffset: CGFloat = 0
    var profileOffsetX: CGFloat = 0
    @ObservationIgnored var presentedProfileOffset: CGFloat = 0
    @ObservationIgnored var presentedProfileOffsetX: CGFloat = 0
}

extension Animation {
    //Spring in Apple's design parameters (WWDC18 "Designing Fluid Interfaces"):
    //response = duration of one oscillation, dampingRatio 1 = comes to rest with no
    //bounce. relativeVelocity = gestureVelocity / (target - current), so released
    //momentum carries into the animation.
    static func fluidSpring(response: CGFloat, dampingRatio: CGFloat, relativeVelocity: CGFloat = 0) -> Animation {
        .interpolatingSpring(
            mass: 1,
            stiffness: pow(2 * .pi / response, 2),
            damping: 4 * .pi * dampingRatio / response,
            initialVelocity: relativeVelocity
        )
    }
}
