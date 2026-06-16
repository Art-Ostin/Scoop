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

    //Profile Images
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

    //1. Details card position. Written every frame of a drag — read ONLY by the
    //drag-effect leaf modifiers in ProfileGestures.swift, never by ProfileView.body,
    //so a moving card invalidates a handful of transforms instead of the whole tree.
    var detailsOffset: CGFloat = 0
    let detailsOpenOffset: CGFloat = -240
    let detailsClosedOffset: CGFloat = 0
    let detailsCardHeight: CGFloat = 600

    //0 = closed detent, 1 = open detent (clamped through the rubber-band range)
    var detailsProgress: CGFloat { progress(for: detailsOffset) }

    //Progress for an arbitrary offset. Pure math on constants — safe to call per
    //animation frame without creating an observation dependency.
    func progress(for offset: CGFloat) -> CGFloat {
        let span = detailsClosedOffset - detailsOpenOffset
        guard span > 0.0001 else { return 0 }
        return min(max((detailsClosedOffset - offset) / span, 0), 1)
    }

    //Maps drag progress onto a value range. impactStart/impactEnd restrict the
    //transition to a sub-range of the drag (e.g. 0.5...1 = last 50%).
    func interpolate(from start: CGFloat, to end: CGFloat, impactStart: CGFloat = 0, impactEnd: CGFloat = 1) -> CGFloat {
        let span = impactEnd - impactStart
        guard span > 0.0001 else { return detailsProgress >= impactEnd ? end : start }
        let t = min(max((detailsProgress - impactStart) / span, 0), 1)
        return start + (end - start) * t
    }

    //2. Details card state
    var detailsOpen: Bool = false
    var detailsFullyOpen: Bool = false
    var isDraggingDetails: Bool = false
    var isAtTopOfScroll = true

    //3. Resting layout of the card. Header height is a size (transform-independent),
    //so it never changes while a drag transform is active.
    let headerTopPadding: CGFloat = 36
    var headerHeight: CGFloat = 0
    var detailsRestingTop: CGFloat { headerTopPadding + headerHeight + 24 }

    @ObservationIgnored var dragType: DragType = .undecided
    @ObservationIgnored var dragBase: CGFloat = 0
    @ObservationIgnored var dragCommitTranslation: CGFloat = 0
    @ObservationIgnored var presentedDetailsOffset: CGFloat = 0
    @ObservationIgnored var restingCardTopGlobal: CGFloat = .infinity
    @ObservationIgnored var containerHeight: CGFloat = 0

    func animateDetails(to willOpen: Bool, velocity: CGFloat = 0) {
        let target = willOpen ? detailsOpenOffset : detailsClosedOffset
        if !willOpen { detailsFullyOpen = false }
        //dampingRatio 1 = no free bounce; overshoot comes only from the flick
        //velocity, which is how the system sheet settles.
        let distance = target - detailsOffset
        let relativeVelocity = abs(distance) > 0.001 ? velocity / distance : 0
        let spring = Animation.fluidSpring(response: 0.30, dampingRatio: 0.8, relativeVelocity: relativeVelocity) //
        withAnimation(spring) {
            detailsOpen = willOpen
            detailsOffset = target
        } completion: { [weak self] in
            //A drag that caught the card mid-snap makes this completion stale — skip.
            guard let self, !self.isDraggingDetails else { return }
            //Settled: model and presentation agree by definition.
            self.presentedDetailsOffset = self.detailsOffset
            if willOpen && self.detailsOpen { self.detailsFullyOpen = true }
        }
    }

    //5. Logic with what screen showing
    var showPopup: Bool = false
    //Cover-mount id for the send-invite morph; outlasts showPopup through the collapse.
    var morphInviteId: String? = nil

    //6. Logic with Profile dismiss. The drag is 2D: profileOffset (y) drives the
    //native-style shrink, profileOffsetX is the damped horizontal follow. The
    //presented* mirrors track the on-screen values through springs (same pattern
    //as presentedDetailsOffset) so a regrab catches a snap-back mid-flight.
    var profileOffset: CGFloat = 0
    var profileOffsetX: CGFloat = 0
    //True from the moment a drag is classified as a dismiss until it snaps back
    //(or the profile unmounts). Observed, but flips only twice per gesture — the
    //pager reads it to pause horizontal scrolling, like the native zoom dismissal
    //locking the content while the transition owns the surface.
    var isDismissDragging: Bool = false
    @ObservationIgnored var presentedProfileOffset: CGFloat = 0
    @ObservationIgnored var presentedProfileOffsetX: CGFloat = 0
    @ObservationIgnored var dragBaseX: CGFloat = 0
    @ObservationIgnored var dragCommitTranslationX: CGFloat = 0
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
