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
    @State private var scrollProgress: Double = 0
    @State private var width: CGFloat = 0

    @State private var nameFrame: CGRect = .zero
    @State private var inviteFrame: CGRect = .zero
    @State private var optionsFrame: CGRect = .zero

    private let overlaySpace = "InviteImageCarousel"

    private var isConfirming: Bool { ui.showConfirmScreen == true }

    private var aspectRatio: AspectRatio {
        isConfirming ? .confirmInviteImage : .invitedImage
    }

    private var imageHeight: CGFloat? { width > 0 ? width / aspectRatio.ratio : nil }

    var body: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            ForEach(images, id: \.self) {image in
                photo(image)
            }
        }
        .getWidth($width)
        .frame(maxHeight: imageHeight) //So the card content fits beneath it
        .overlay { backgroundBlur }
        .overlay(alignment: .top) { topOverlay }
        .overlay(alignment: .bottom) { pageIndicator }
        .coordinateSpace(.named(overlaySpace)) //Last, so the overlays measure inside the space
    }
}

//The Pager
extension InviteImageCarousel {

    private func photo(_ image: UIImage) -> some View {
        Color.clear
            .aspectRatio(aspectRatio.ratio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped() //scaledToFill overflows the page cell
            .containerRelativeFrame(.horizontal)
    }

    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7)
            .padding(.bottom, Spacing.xs)
            .opacityPop(visible: !isConfirming)
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
        .opacityPop(visible: !isConfirming)
        .overlay(alignment: .leading) { confirmBackButton }
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

    private func halo(_ image: UIImage) -> some View {
        BackgroundBlur(image: image, frames: [nameFrame, inviteFrame, optionsFrame])
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
        .opacityPop(visible: !isConfirming)
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
