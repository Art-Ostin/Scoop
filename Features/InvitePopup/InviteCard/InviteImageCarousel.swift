//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InviteImageCarousel: View {

    //Only show 'clear Invite' in options Menu if there are changes to invite
    let inviteHasChanges: Bool
        
    //Responding to an invite: titles it "<name>'s Invite" and hides the page indicators
    let isInvite: Bool
    
    let name: String
    let images: [UIImage]

    //When confirming an Invite or responding to an invite need to shrink the image and hide overlays
    let isCompact: Bool

    //the back button out of the confirm screen overlays the image
    @Binding var showConfirmScreen: Bool?
    
    //The options menu triggers infoScreen
    @Binding var showInfoScreen: Bool
    
    let declineProfile: () -> Void
    let clearInvite: () -> Void
    
    //Stores scrollProgress needed the animatedPageIndicator
    @State private var scrollProgress: Double = 0
    
    //Gets the CGRects for all the imageoverlayContent, to apply a blur behind them
    @State private var nameFrame: CGRect = .zero
    @State private var inviteFrame: CGRect = .zero
    @State private var optionsFrame: CGRect = .zero
    
    var body: some View {
        InviteCarousel(images: images, isCompact: isCompact, scrollProgress: $scrollProgress)
            .overlay { backgroundBlur }
            .overlay(alignment: .topTrailing) { optionsMenu }
            .overlay(alignment: .bottomLeading) { titleOverlay}
            .overlay(alignment: .bottomTrailing) { if !isInvite { pageIndicator } }
            .overlay(alignment: .topLeading) { if showConfirmScreen == true { confirmBackButton} }
            .coordinateSpace(.named("InviteImageCarousel")) //Last, so the overlays measure inside the space
    }
}

//Key Overlays
extension InviteImageCarousel {

    private var topOverlay: some View {
        
        
        HStack {
//            if !isInvite {nameOverlay}
            Spacer()
            optionsMenu
        }
    }
        
    private var backgroundBlur: some View {
        let progress = min(max(scrollProgress, 0), Double(images.count - 1))
        let page = Int(progress)
        let next = min(page + 1, images.count - 1)
        let fraction = progress - Double(page)

        return ZStack {
            BackgroundBlur(image: images[page], frames: [nameFrame, inviteFrame, optionsFrame])
                .opacity(1 - fraction)
            if next != page && fraction > 0 {
                BackgroundBlur(image: images[next], frames: [nameFrame, inviteFrame, optionsFrame])
                    .opacity(fraction)
            }
        }
        .opacity(isCompact ? 0 : 1)
    }
}

//Components
extension InviteImageCarousel {
    
    //"Invite" is the one word every state shares, so it sits unconditionally in the middle
    //of the stack and only ever slides and scales — the side words come and go around it.
    private var titleOverlay: some View {
        HStack(spacing: 6) {
            if let leadingWord {
                Text(leadingWord)
                    .getRect($nameFrame, coordSpace: "InviteImageCarousel")
                    .transition(.blurReplace)
            }

            Text(isCompact && !isInvite ? "invite" : "Invite")
                .getRect($inviteFrame, coordSpace: "InviteImageCarousel")

            if showsTrailingName {
                Text(name)
                    .getRect($nameFrame, coordSpace: "InviteImageCarousel")
                    .transition(.blurReplace)
            }
        }
        .font(.title(24))
        .contentTransition(.opacity) //Crossfades the "Invite"/"invite" case flip instead of popping it
        .foregroundStyle(Color.white)
        .scaleEffect(titleScale, anchor: .bottomLeading) //Matches the overlay's alignment, so the leading edge stays pinned
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    //Pushes "Invite" right: "Sarah's" when responding, "Confirm" once a send reaches the confirm screen
    private var leadingWord: String? {
        if isInvite { "\(name)'s" }
        else if isCompact { "Confirm" }
        else { nil }
    }

    //The invitee's name trails "Invite" only while the send is still being edited
    private var showsTrailingName: Bool { !isInvite && !isCompact }

    //Compact type is 18pt against the 24pt resting size — a font swap snaps, a scale animates
    private var titleScale: CGFloat { isCompact ? 18 / 24 : 1 }
    
    private var optionsMenu: some View {
        OptionsMenu(
            showOptions: !isCompact,
            hasChanges: inviteHasChanges,
            optionsFrame: $optionsFrame,
            onDecline: {declineProfile()},
            deleteDraft: { clearInvite()},
            onInfo: {showInfoScreen = true }
        )
        .padding(Spacing.lg)
        
        
    }

    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7, anchor: .trailing)
            .padding(.horizontal, 24)
            .padding(.bottom, Spacing.xs)
            .opacityPop(visible: !isCompact)
    }
    
    private var confirmBackButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: {showConfirmScreen = false}) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .blurPop(visible: isCompact)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
