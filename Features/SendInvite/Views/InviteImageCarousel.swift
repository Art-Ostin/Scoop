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
    
    @State private var nameFrame: CGRect = .zero
    @State private var inviteFrame: CGRect = .zero
    @State private var optionsFrame: CGRect = .zero

    private var isConfirming: Bool { ui.showConfirmScreen == true }

    var body: some View {
        InviteCarousel(images: images, isConfirming: isConfirming, scrollProgress: $scrollProgress)
        .overlay { backgroundBlur }
        .overlay(alignment: .top) { topOverlay }
        .overlay(alignment: .bottom) { pageIndicator }
        .coordinateSpace(.named("InviteImageCarousel")) //Last, so the overlays measure inside the space
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
        .opacityPop(visible: !isConfirming)
        .overlay(alignment: .leading) { confirmBackButton }
    }
    
    private var optionsMenu: some View {
        OptionsMenu(
            vm: vm,
            isConfirming: isConfirming,
            optionsFrame: $optionsFrame,
            onDecline: {declineProfile()},
            onInfo: { ui.showInfoScreen = true}
        )
    }

    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7)
            .padding(.bottom, Spacing.xs)
            .opacityPop(visible: !isConfirming)
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


struct InviteCarousel: View {
    
    //Injected Properties
    let images: [UIImage]
    let isConfirming: Bool
    
    @Binding var scrollProgress: Double
    
    //Local Properties
    @State private var width: CGFloat = 0
    
    private var imageHeight: CGFloat? {
        width > 0 ? width / aspectRatio.ratio : nil
    }

    private var aspectRatio: AspectRatio {
        isConfirming ? .confirmInviteImage : .invitedImage
    }
    
    var body: some View {
        HorizontalScrollView(progress: $scrollProgress) {
            ForEach(images, id: \.self) {image in
                photo(image)
            }
        }
        .getWidth($width)
        .frame(maxHeight: imageHeight) //So the card content fits beneath it
    }
    
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
}

