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
    
    //Only used if not responding
    let isConfirm: Bool

    //A menu is on screen below: the title and page indicator pop away for it
    let isPopupOpen: Bool

    //In response mode when not nil
    var responseType: Binding<ResponseType>? = nil
    var isRespondScreen: Bool { responseType != nil && responseType?.wrappedValue != .newEvent}
    var showOverlayText: Bool { isRespondScreen || !isConfirm }
    
    let name: String
    let images: [UIImage]
    
    //The back button out of the confirm screen overlays the image
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
        InviteCarousel(images: images, isCompact: isConfirm, scrollProgress: $scrollProgress)
            .overlay { if showOverlayText { backgroundBlur } }
            .overlay(alignment: .topTrailing) { optionsMenu }
            .overlay(alignment: .bottomLeading) { popupTitle }
            .overlay(alignment: .bottomTrailing) { pageIndicator }
            .overlay(alignment: .topLeading) { if showConfirmScreen == true { confirmBackButton} }
            .coordinateSpace(.named("InviteImageCarousel")) //Last, so the overlays measure inside the space
    }
}

//Background Blur
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
        isConfirm ? [nameFrame, inviteFrame] : [nameFrame, inviteFrame, optionsFrame]
    }
}


extension InviteImageCarousel {
    
    
    private var popupTitle: some View {
        let firstWord: String = isRespondScreen ? "\(name)'s" : "Invite"
        let secondWord: String = isRespondScreen ? "invite" : "\(name)"

        return HStack(spacing: 6) {
            Text(firstWord)
                .getRect($nameFrame, coordSpace: "InviteImageCarousel")

            Text(secondWord)
                .getRect($inviteFrame, coordSpace: "InviteImageCarousel")
        }
        .font(.title(22))
        .scaleEffect(isRespondScreen ? 0.85 : 1, anchor: .bottomLeading)
        .foregroundStyle(Color.white)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .opacityPop(visible: showOverlayText)
        .animation(.transition, value: showOverlayText)
    }
    
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
        .opacityPop(visible: !isPopupOpen)
        .animation(.transition, value: isPopupOpen) //opacityPop carries no curve of its own
        .animation(.transition, value: showsOptions)
    }
    
    private var showsOptions: Bool {
        guard !isConfirm else { return false }
        guard let responseType else { return true } //Send mode always offers the menu
        return responseType.wrappedValue == .newEvent //If is response mode, only show options if new event
    }
    
    private var pageIndicator: some View {
        let visible = !isPopupOpen && !isConfirm

        return ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7, anchor: .trailing)
            .padding(.horizontal, 24)
            .padding(.bottom, Spacing.xs)
            .opacityPop(visible: visible)
            .animation(.transition, value: visible)
    }
    
    private var confirmBackButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: {showConfirmScreen = false}) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .blurPop(visible: isConfirm)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
