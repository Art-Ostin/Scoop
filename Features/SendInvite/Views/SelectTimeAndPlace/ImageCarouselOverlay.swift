//
//  ImageCarouselOverlay.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InviteImageOverlays: ViewModifier {

    //Injected
    @Bindable var vm: TimeAndPlaceViewModel
    
    let scrollProgress: Double
    let name: String
    
    let expanded: Bool
    let showCollapsedChrome: Bool
    
    let details: String
    let coverImage: UIImage?
    
    let images: [UIImage] //For background overlays

    @Binding var confirmScreen: Bool
    @Binding var showInfoScreen: Bool
    @Binding var inviteButtonPopped: Bool

    let declineProfile: () -> Void
    
    //Local
    @State var nameFrame: CGRect = .zero
    @State var inviteFrame: CGRect = .zero
    @State var optionsFrame: CGRect = .zero
    
    let imageCount = 6
    
    func body(content: Content) -> some View {
        content
            .overlay { imageTransition }
            .overlay { backgroundBlur }
            .overlay(alignment: .top) { topOverlay }
            .overlay(alignment: .bottomLeading) { transitionInfo }
            .overlay(alignment: .bottomTrailing) { inviteButtonTransition }
    }
}

//Key Overlays
extension InviteImageOverlays {
    
    private var topOverlay: some View {
        HStack {
            nameOverlay
            Spacer()
            optionsMenu
        }
        .padding(.top, 12)
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
    
    private var nameOverlay: some View {
        HStack(spacing: 6) {
            Text("Invite")
                .getRect($inviteFrame, coordSpace: InviteImageCarousel.imageSpace)

            Text(name)
                .getRect($nameFrame, coordSpace: InviteImageCarousel.imageSpace)
        }
        .font(.title(24))
        .foregroundStyle(Color.white)
        .opacityPop(visible: expanded)
        .blurPop(visible: !confirmScreen)
        .overlay(alignment: .leading) { confirmBackButton }
    }
    
    private var backgroundBlur: some View {
        let progress = min(max(scrollProgress, 0), Double(imageCount - 1))
        let page = Int(progress)
        let next = min(page + 1, imageCount - 1)
        let fraction = progress - Double(page)

        return ZStack {
            BackgroundBlur(image: coverImage ?? images[page], frames: [nameFrame, inviteFrame, optionsFrame])
                .opacity(1 - fraction)
            if coverImage == nil && next != page && fraction > 0 {
                BackgroundBlur(image: images[next], frames: [nameFrame, inviteFrame, optionsFrame])
                    .opacity(fraction)
            }
        }
        .opacity(expanded && !confirmScreen ? 1 : 0)
    }
        
    private var confirmBackButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: {confirmScreen = false}) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .blurPop(visible: confirmScreen)
    }
}

//Options Menu
extension InviteImageOverlays {
    
    //The Actual OptionMenuButton
    private var optionsMenu: some View {
        Menu {
            infoButton
            if vm.event.hasChanges { clearInviteButton}
            declineButton
        } label: {
            optionsLabel
        }
        .padding(-Spacing.sm)
        .blurPop(visible: expanded)
        .sheet(isPresented: $showInfoScreen) { Text("Info screen here") }
    }
    
    //The Three button Rows
    private var infoButton: some View {
        Button("How Invites Work", systemImage: "info.circle") {
            showInfoScreen = true
        }
    }
    
    private var clearInviteButton: some View {
        Button {
            withAnimation(.transition) {
                vm.deleteEventDefault()
            }
        } label: {
            Label {
                Text("Clear Invite Draft")
            } icon: {
                Image("BinIcon")
                    .renderingMode(.template)
                    .scaleEffect(1.2)
            }
        }
    }

    private var declineButton: some View {
        Button(role: .destructive) {
            declineProfile()
        } label: {
            Label {
                Text("Decline Profile")
            } icon: {
                Image(systemName: "xmark")
                    .font(.body(14, .bold))
            }
        }
    }
    
    //The Options Label
    private var optionsLabel: some View {
        HStack(spacing: 4) {
            circle
            circle
            circle
        }
        .scaleEffect(0.95)
        .padding(2)
        .background {
            Capsule()
                .fill(Color.black.opacity(0.04))
                .blur(radius: 2)
        }
        .getRect($optionsFrame, coordSpace: InviteImageCarousel.imageSpace)
        .padding(Spacing.sm - 2)//Offset interior padding with capsule
        .contentShape(Circle())
        .offset(y: -2)//
    }
    
    private var circle: some View {
        Circle()
            .fill(.white.opacity(0.8))
            .frame(width: 4.5, height: 4.5)
    }
}


//Overlays for the Transition Only
extension InviteImageOverlays {
    
    @ViewBuilder
    private var transitionInfo: some View {
        if showCollapsedChrome {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(name)
                    .font(.title(26))
                Text(details)
                    .font(.body(14, .medium))
            }
            .foregroundStyle(Color.white)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal)
            .opacity(expanded ? 0 : 1)
            .blur(radius: expanded ? 6 : 0)
            .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    private var inviteButtonTransition: some View {
        if showCollapsedChrome {
            InviteButton(isInviting: true, action: {})
                .scaleEffect(inviteButtonPopped ? 1 : PressEffect.shrink.scale)
                .opacityPop(visible: !expanded)
                .padding([.trailing, .bottom], Spacing.md)
                .allowsHitTesting(false)
                .task {
                    withAnimation(.spring(response: PressEffect.shrink.release.response,
                                          dampingFraction: PressEffect.shrink.release.damping)) {
                        inviteButtonPopped = true
                    }
                }
        }
    }
    
    private var imageTransition: some View {
        Color.clear
            .overlay {
                Image(uiImage: coverImage ?? images[0])
                    .resizable()
                    .scaledToFill()
            }
            .opacity(coverImage != nil && expanded ? 1 : 0)
            .allowsHitTesting(false)
    }
}
