//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InviteImageCarousel: View {

    //Injected
    let vm: TimeAndPlaceViewModel
    let ui: TimeAndPlaceUIState

    let name: String
    let images: [UIImage]

    let declineProfile: () -> Void

    //Local
    @State private var nameFrame: CGRect = .zero
    @State private var inviteFrame: CGRect = .zero
    @State private var optionsFrame: CGRect = .zero

    private let overlaySpace = "InviteImageCarousel"

    private var isConfirming: Bool { ui.showConfirmScreen == true }

    private var aspectRatio: AspectRatio {
        isConfirming ? .confirmInviteImage : .invitedImage
    }

    var body: some View {
        ImageCarouselOld(images: images, type: .invite, aspectRatio: aspectRatio)
            .overlay { backgroundBlur }
            .overlay(alignment: .top) { topOverlay }
            .coordinateSpace(.named(overlaySpace)) //Last, so the overlays measure inside the space
    }
}

//Key Overlays
extension InviteImageCarousel {

    private var topOverlay: some View {
        HStack {
            nameOverlay
            Spacer()
            optionsMenu
        }
        .padding(.top, Spacing.sm)
        .padding(.horizontal, Spacing.md)
    }

    private var nameOverlay: some View {
        HStack(spacing: 6) {
            Text("Invite")
                .getRect($inviteFrame, coordSpace: overlaySpace)

            Text(name)
                .getRect($nameFrame, coordSpace: overlaySpace)
        }
        .font(.title(24))
        .foregroundStyle(Color.white)
        .blurPop(visible: !isConfirming)
        .overlay(alignment: .leading) { confirmBackButton }
    }

    //Halo behind the overlaid text. Reads the first image only — the carousel keeps its scroll progress private.
    @ViewBuilder
    private var backgroundBlur: some View {
        if let image = images.first {
            BackgroundBlur(image: image, frames: [nameFrame, inviteFrame, optionsFrame])
                .opacity(isConfirming ? 0 : 1)
        }
    }

    private var confirmBackButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: {ui.showConfirmScreen = false}) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .blurPop(visible: isConfirming)
    }
}

//Options Menu
extension InviteImageCarousel {

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
    }

    //The Three button Rows
    private var infoButton: some View {
        Button("How Invites Work", systemImage: "info.circle") {
            ui.showInfoScreen = true
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
            ForEach(0..<3, id: \.self) { _ in circle }
        }
        .scaleEffect(0.95)
        .padding(2)
        .background {
            Capsule()
                .fill(Color.black.opacity(0.04))
                .blur(radius: 2)
        }
        .getRect($optionsFrame, coordSpace: overlaySpace)
        .padding(Spacing.sm - 2)//Offset interior padding with capsule
        .contentShape(Circle())
        .offset(y: -2)
    }

    private var circle: some View {
        Circle()
            .fill(.white.opacity(0.8))
            .frame(width: 4.5, height: 4.5)
    }
}
