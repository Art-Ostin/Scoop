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
        
    //Always hide name overlay and page indicators if its responding to invite
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
            .overlay(alignment: .top) { topOverlay }
            .overlay(alignment: .bottom) { if !isInvite { pageIndicator } }
            .coordinateSpace(.named("InviteImageCarousel")) //Last, so the overlays measure inside the space
    }
}

//Key Overlays
extension InviteImageCarousel {

    private var topOverlay: some View {
        HStack {
            if !isInvite {nameOverlay}
            Spacer()
            optionsMenu
        }
        .padding(.top, Spacing.sm)
        .padding(.horizontal, Spacing.md)
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
        .opacity(isCompact ? 1 : 0)
    }
}

//Components
extension InviteImageCarousel {
    
    private var nameOverlay: some View {
        HStack(spacing: 6) {
            Text("Invite")
                .getRect($inviteFrame, coordSpace: "InviteImageCarousel")

            Text(name)
                .getRect($nameFrame, coordSpace: "InviteImageCarousel")
        }
        .font(.title(24))
        .foregroundStyle(Color.white)
        .opacityPop(visible: !isCompact)
        .overlay(alignment: .leading) { confirmBackButton }
    }
    
    private var optionsMenu: some View {
        OptionsMenu(
            showOptions: !isCompact || isInvite,
            hasChanges: inviteHasChanges,
            optionsFrame: $optionsFrame,
            onDecline: {declineProfile()},
            deleteDraft: { clearInvite()},
            onInfo: {showInfoScreen = true }
        )
    }

    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7)
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
    }
}

//The ImageScrollView

struct InviteCarousel: View {

    //Injected Properties
    let images: [UIImage]
    let isCompact: Bool

    @Binding var scrollProgress: Double

    private var ratio: CGFloat {
        (isCompact ? AspectRatio.confirmInviteImage : .invitedImage).ratio
    }

    var body: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            ForEach(images, id: \.self) { photo($0) }
        }
        .aspectRatio(ratio, contentMode: .fit) //Sizes the greedy pager to the image shape
    }

    private func photo(_ image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped() //scaledToFill overflows the page cell
            .containerRelativeFrame(.horizontal)
    }
}



/*
 
 private func halo(_ image: UIImage) -> some View {
     BackgroundBlur(image: image, frames: [nameFrame, inviteFrame, optionsFrame])
 }

 @ViewBuilder
 private var backgroundBlur: some View {
     if !images.isEmpty {
         let progress = scrollProgress.clamped(to: 0...Double(images.count - 1))
         let page = Int(progress)
         let fraction = progress - Double(page)
         halo(images[page])
             .overlay {
                 halo(images[min(page + 1, images.count - 1)])
                     .opacity(fraction)
             }
             .opacity(isConfirming ? 0 : 1)
     }
 }

 
 */
