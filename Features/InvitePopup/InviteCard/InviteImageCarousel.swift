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
         case .newInviteConfirm: Overlays(backButton: true, toggle: true, compactImage: true)
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

    //Both offered by the options menu
    let declineProfile: () -> Void
    let clearInvite: () -> Void

    //Local view state
    @State private var scrollProgress: Double = 0

    //Measured so the blur halo can lift just behind the overlay text
    @State private var nameFrame: CGRect = .zero
    @State private var inviteFrame: CGRect = .zero
    @State private var optionsFrame: CGRect = .zero

    private var chrome: InviteScreen.Overlays  { screen.chrome }

    var body: some View {
        InviteCarousel(images: images, isCompact: chrome.compactImage, scrollProgress: $scrollProgress)
            .overlay(alignment: .topLeading) { backButton }
            .overlay(alignment: .topTrailing) { topRow }
            .overlay(alignment: .bottomLeading) { inviteTitle }
            .overlay(alignment: .bottomTrailing) { pageIndicator }
            .overlay { backgroundBlur }
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
        .chromeItem(visible: chrome.backButton)
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
                    optionsFrame: $optionsFrame,
                    onDecline: declineProfile,
                    deleteDraft: clearInvite,
                    onInfo: { showInfoScreen = true }
                )
            }
        }
        .padding(Spacing.sm)
        .chromeItem(visible: !isPopupOpen)
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
        .chromeItem(visible: chrome.title)
    }
    
    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7, anchor: .trailing)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xs)
            .chromeItem(visible: chrome.pageIndicator && !isPopupOpen)
    }
    
    //Apply background blur where necessary under the content
    private var backgroundBlur: some View {
        let progress = min(max(scrollProgress, 0), Double(images.count - 1))
        let page = Int(progress)
        let next = min(page + 1, images.count - 1)
        let fraction = progress - Double(page)

        return ZStack {
            BackgroundBlur(image: images[page], frames: haloFrames)
                .opacity(1 - fraction)
            if next != page && fraction > 0 {
                BackgroundBlur(image: images[next], frames: haloFrames)
                    .opacity(fraction)
            }
        }
        .chromeItem(visible: chrome.title) //Only shows
    }
    
    private var haloFrames: [CGRect] {
        chrome.options ? [nameFrame, inviteFrame, optionsFrame] : [nameFrame, inviteFrame]
    }
}

//All Overlay Items are shown and hidden in exactly the same way. So convenience modifier created here
private extension View {
    func chromeItem(visible: Bool) -> some View {
        opacityPop(visible: visible)
            .allowsHitTesting(visible)
            .animation(.transition, value: visible)
    }
}
