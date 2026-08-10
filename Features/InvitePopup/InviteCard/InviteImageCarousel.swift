//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//
enum InviteScreen {
    //The Five Different Image Screens Possible
    case send, sendConfirm
    case accept, newInvite, newInviteConfirm

    //A struct storing all overlay booleans for the view
    struct Overlays {
        var backButton = false
        var options = false
        var toggle = false
        var title = false
        var pageIndicator = false
        var compactImage = false
    }

    //For Each view, now declare which overlay visible or not
    var chrome: Overlays {
        switch self {
        case .send:             Overlays(options: true, title: true, pageIndicator: true)
        case .newInvite:        Overlays(options: true, toggle: true, title: true, pageIndicator: true)
        case .accept:           Overlays(toggle: true, title: true, compactImage: true)
        case .sendConfirm:      Overlays(backButton: true, compactImage: true)
        case .newInviteConfirm: Overlays(backButton: true, compactImage: true)
        }
    }

    //Only the two composing screens soften the artwork's bottom — the title and dots sit on it there
    var blursBottom: Bool {
        switch self {
        case .send, .newInvite:                        true
        case .accept, .sendConfirm, .newInviteConfirm: false
        }
    }
}


import SwiftUI
struct InviteImageCarousel: View {

    //Injected Properties
    let screen: InviteScreen
    let name: String
    let images: [UIImage]

    //Only offer 'Clear Invite' in the options menu once the draft has something to clear
    let inviteHasChanges: Bool

    //A menu owns the card below: the top row and the page indicator pop away for it
    let isPopupOpen: Bool

    //The back button leaves the confirm screen & Options Menu opens Info Screen
    @Binding var showConfirmScreen: Bool?
    @Binding var showInfoScreen: Bool

    //Respond screens only — the toggle swaps between their invite and one of your own
    var responseType: Binding<ResponseType>? = nil

    //The invite flight frames this carousel itself instead of letting it self-size
    var fillsFrame: Bool = false

    //The flight owns the page position when it needs the cover dissolve on close
    var scrollProgress: Binding<Double>? = nil

    //…and snaps the pager home under that cover before the collapse resizes it
    var pagerPosition: Binding<ScrollPosition>? = nil

    //False until the open flight's tail, so the chrome pops in at its resting position over the flying image
    var chromeVisible: Bool = true

    //The flight defers the heavy pager until the card lands — its static covers stand in
    //beneath this view meanwhile, so only the chrome overlays render during the flight
    var showsPager: Bool = true

    //The landing crossfade: the pager fades in over the flight's held sharp cover, so the
    //pages' bottom blur arrives smoothly instead of snapping in with the mount
    var pagerFade: Double = 1

    //…and stays inert until that cover drops — paging a semi-transparent pager over a held
    //cover double-exposes two photos
    var pagerInteractive: Bool = true

    //Both offered by the options menu
    let declineProfile: () -> Void
    let clearInvite: () -> Void

    //Local view state
    @State private var internalScrollProgress: Double = 0

    //Measured so the blur halo can lift just behind the overlay text
    @State private var nameFrame: CGRect = .zero
    @State private var inviteFrame: CGRect = .zero

    private var chrome: InviteScreen.Overlays { screen.chrome }

    private var progressBinding: Binding<Double> { scrollProgress ?? $internalScrollProgress }
    private var progress: Double { progressBinding.wrappedValue }

    var body: some View {
        ZStack {
            if showsPager {
                InviteCarousel(images: images, isCompact: chrome.compactImage, blursBottom: screen.blursBottom, fillsFrame: fillsFrame, position: pagerPosition, scrollProgress: progressBinding)
                    .opacity(pagerFade)
                    .allowsHitTesting(pagerInteractive)
            } else {
                Color.clear //The flight frames this carousel before the pager mounts; without a filled base the corner-pinned overlays collapse to a zero-size centre
            }
        }
            .overlay { backgroundBlur }
            .overlay(alignment: .topLeading) { backButton }
            .overlay(alignment: .topTrailing) { topRow }
            .overlay(alignment: .bottomLeading) { inviteTitle }
            .overlay(alignment: .bottomTrailing) { pageIndicator }
            .coordinateSpace(.named("InviteImageCarousel")) //Last, so the overlays measure inside the space
    }
}

//The overlays
extension InviteImageCarousel {

    //Top Right to Bottom Left, the Four different visible Screens
    private var backButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: { showConfirmScreen = false }) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .chromeItem(visible: chrome.backButton && chromeVisible)
        .padding(.horizontal, 20) //Geometry: as the title — one shared inset from the artwork edge
        .padding(.top, Spacing.sm)
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            if chrome.toggle, let responseType {
                ChangeButton(responseType: responseType, showConfirmScreen: $showConfirmScreen)
            }

            if chrome.options {
                OptionsMenu(
                    hasChanges: inviteHasChanges,
                    onInfo: { showInfoScreen = true },
                    onClear: clearInvite,
                    onDecline: declineProfile
                )
            }
        }
        .padding(Spacing.sm)
        .chromeItem(visible: !isPopupOpen && chromeVisible)
        .animation(.transition, value: screen) //Its two buttons mount and unmount as the screen changes
    }

    private var inviteTitle: some View {
        let answering = screen == .accept

        return HStack(spacing: 6) { //Geometry: tighter than a word space, so the pair reads as one line of display type
            Text(answering ? "\(name)'s" : "Invite")
                .getRect($nameFrame, coordSpace: "InviteImageCarousel")

            Text(answering ? "invite" : name)
                .getRect($inviteFrame, coordSpace: "InviteImageCarousel")
        }
        .font(.title(22))
        .scaleEffect(answering ? 0.85 : 1, anchor: .bottomLeading) //Their name runs longer than "Invite"
        .foregroundStyle(Color.white)
        .padding(.horizontal, 20)
        .padding(.bottom, Spacing.sm)
        .chromeItem(visible: chrome.title && chromeVisible)
    }

    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: progress, activeColor: .white)
            .scaleEffect(0.7, anchor: .trailing)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xs)
            .chromeItem(visible: chrome.pageIndicator && !isPopupOpen && chromeVisible)
    }

    //Apply background blur where necessary under the content
    private var backgroundBlur: some View {
        let clamped = min(max(progress, 0), Double(images.count - 1))
        let page = Int(clamped)
        let next = min(page + 1, images.count - 1)
        let fraction = clamped - Double(page)
        //Gated on the pager: the halo is a blur effect and must not render during the flight
        let visible = chrome.title && chromeVisible && showsPager

        return ZStack {
            BackgroundBlur(image: images[page], frames: [nameFrame, inviteFrame])
                .opacity(1 - fraction)
            if next != page && fraction > 0 {
                BackgroundBlur(image: images[next], frames: [nameFrame, inviteFrame])
                    .opacity(fraction)
            }
        }
        //A full-bleed wash has no corner to pop from — scaling it drags both halos toward the middle.
        //BackgroundBlur already refuses hits, so a plain fade is all it needs.
        .opacity(visible ? 1 : 0)
        .animation(.transition, value: visible)
    }
}

//All Overlay Items are shown and hidden in exactly the same way. So convenience modifier created here
private extension View {
    //anchor: the corner the overlay is pinned to, so it pops from there rather than drifting to its own centre
    func chromeItem(visible: Bool, anchor: UnitPoint = .center) -> some View {
        opacityPop(visible: visible, anchor: anchor)
            .allowsHitTesting(visible)
            .animation(.transition, value: visible)
    }
}
