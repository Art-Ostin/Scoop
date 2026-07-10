//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

//The settled invite image: paged profile photos with the name and options menu.
//Lives under the flight copy and takes over once it lands.
struct InviteImageCarousel: View {
    //Injected
    let images: [UIImage]
    let name: String
    @Binding var scrollProgress: Double
    let vm: TimeAndPlaceViewModel //@Observable class — drives the options menu (clear draft)
    var dragDisabled: Bool = false //Swipe-dismiss owns the touch: no paging, even mid-pan
    var optionsVisible: Bool = true //Flips at drag release so the menu is already popped in when the settle swap lands

    //Local view state
    @State private var meetFrame: CGRect = .zero
    @State private var nameFrame: CGRect = .zero
    @State private var showInfoScreen = false //"How Invites Work" sheet, opened from the options menu

    private static let imageSpace = "InviteImageCarousel.image"
    //Name inset from the image edge; the flight matches these so the settle handoff lands (see cardOverlay padding)
    static let nameLeadingInset: CGFloat = 17
    static let nameTopInset: CGFloat = 12

    var body: some View {
        CardImageCarousel(images: images, scrollProgress: $scrollProgress)
            .scrollDisabled(images.count <= 1 || dragDisabled)
            .overlay { backgroundBlur }
            .overlay(alignment: .top) { cardOverlay }
            .coordinateSpace(name: Self.imageSpace)
    }
}

extension InviteImageCarousel {

    private var cardOverlay: some View {
        HStack {
            nameOverlay
            Spacer()
            optionsMenu
        }
        .padding(.vertical, Self.nameTopInset)
        .padding(.horizontal, Self.nameLeadingInset)
    }

    //Two Texts (not one string) so the glyph layout matches the flight's copy at the handoff.
    private var nameOverlay: some View {
        HStack(spacing: 2) {
            Text("Meet")
                .getRect($meetFrame, coordSpace: Self.imageSpace)
            Text(name)
                .getRect($nameFrame, coordSpace: Self.imageSpace)
        }
        .font(.title(26))
        .foregroundStyle(Color.white)
    }

    private var optionsMenu: some View {
        Menu {
            if vm.event.hasChanges {
                Button("Clear Draft", systemImage: "trash", role: .destructive) {
                    withAnimation(.spring(duration: 0.2)) { vm.deleteEventDefault() }
                }
            }
            Button("How Invites Work", systemImage: "info.circle") {
                showInfoScreen = true
            }
        } label: {
            InviteOptionsIcon()
                .padding(Spacing.xs)
                .shrinkPress()
                .contentShape(Circle())
        }
        .padding(-Spacing.xs)
        .blurPop(visible: optionsVisible)
        .sheet(isPresented: $showInfoScreen) { Text("Info screen here") }
    }

    //Cross-fades the two neighbouring pages' halos so the blur tracks the scroll progressively.
    private var backgroundBlur: some View {
        let progress = min(max(scrollProgress, 0), Double(images.count - 1))
        let page = Int(progress)
        let next = min(page + 1, images.count - 1)
        let fraction = progress - Double(page)

        return ZStack {
            BackgroundBlur(image: images[page], frames: [nameFrame, meetFrame])
                .opacity(1 - fraction)
            if next != page && fraction > 0 {
                BackgroundBlur(image: images[next], frames: [nameFrame, meetFrame])
                    .opacity(fraction)
            }
        }
    }
}
