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
    
    //Always true if responding to an event. Ensuring the 'Change button' always visible in this mode
    var responseType: Binding<ResponseType>? = nil
     
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
    }

    private var haloFrames: [CGRect] {
        isCompact ? [nameFrame, inviteFrame] : [nameFrame, inviteFrame, optionsFrame]
    }
}

//Title Overlay
extension InviteImageCarousel {
    
    
    
    
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
        .animatableTitle(titleSize, titleWeight)
        .contentTransition(.opacity) //Crossfades the "Invite"/"invite" case flip instead of popping it
        .foregroundStyle(Color.white)
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

    //Real point sizes, interpolated by AnimatableTitleFont — each state names its own
    private var titleSize: CGFloat {
        if isInvite { 22 }        //Responding: "<name>'s Invite"
        else if isCompact { 18 }  //Confirm screen
        else { 24 }               //Editing a send
    }

    //Discrete: a family swap can't tween, so it lands on the first frame of the size animation
    private var titleWeight: Font.titleFontWeight { isInvite ? .semibold : .bold }
}

//TopTrailing bar overlay
extension InviteImageCarousel {
    
    
    private var optionsMenu: some View {
        HStack(alignment: .top, spacing: 16) {

            //Only show when its in response mode (so there is a response type)
            if let responseType {
                ChangeButton(responseType: responseType, showConfirmScreen: $showConfirmScreen)
            }
            
            if showsOptions {
                OptionsMenu(
                    hasChanges: inviteHasChanges,
                    optionsFrame: $optionsFrame,
                    onDecline: {declineProfile()},
                    deleteDraft: { clearInvite()},
                    onInfo: {showInfoScreen = true }
                )
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .padding(12)
        .animation(.transition, value: showsOptions)
    }
    
    
    private var showsOptions: Bool {
        guard !isCompact else { return false }
        guard let responseType else { return true } //Send mode always offers the menu
        return responseType.wrappedValue == .newEvent
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

//Animatable type size
//`Font` isn't `VectorArithmetic`, so swapping .font() between sizes snaps. Interpolating the
//point size instead re-lays the text at real metrics every frame, which is what lets each
//state pick its own size outright rather than a ratio off one resting size.
private struct AnimatableTitleFont: ViewModifier, Animatable {

    var size: CGFloat
    var weight: Font.titleFontWeight = .bold

    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content.font(.title(size, weight))
    }
}

private extension View {

    func animatableTitle(_ size: CGFloat, _ weight: Font.titleFontWeight = .bold) -> some View {
        modifier(AnimatableTitleFont(size: size, weight: weight))
    }
}
