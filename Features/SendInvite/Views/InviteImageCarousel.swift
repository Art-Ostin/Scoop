//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

//The settled invite image: paged profile photos with the name and a glass back
//button. Lives under the flight copy and takes over once it lands.
struct InviteImageCarousel: View {

    let images: [UIImage]
    let name: String
    let size: CGSize
    let showsHideButton: Bool
    var dragDisabled: Bool = false //Swipe-dismiss owns the touch: no paging, even mid-pan
    var optionsVisible: Bool = true //Flips at drag release so the menu is already popped in when the settle swap lands
    @Binding var scrollProgress: Double
    let vm: TimeAndPlaceViewModel //@Observable class — drives the options menu (clear draft)
    @Binding var showInfoScreen: Bool

    let onBack: () -> Void

    @State private var scrolledPageID: Int?
    @State private var pageWidth: CGFloat = 0
    @State private var nameFrame: CGRect = .zero
    @State private var hideButtonHeight: CGFloat = 0

    private static let imageSpace = "InviteImageCarousel.image"
    private static let pageSpacing: CGFloat = 4 //Visual gap between pages; built into each cell, never HStack spacing

    //Top-leading name insets. SendInviteFlight's top-name copy + its blur halo reuse these so the settle handoff is pixel-identical.
    static let nameTopInset: CGFloat = 12
    static let nameLeadingInset: CGFloat = 17
    

    var body: some View {
        pager
            .overlay { backgroundBlur }
            .overlay(alignment: .topLeading) { nameOverlay }
            .overlay(alignment: .topTrailing) { optionsMenu }
            .coordinateSpace(name: Self.imageSpace)
    }
}

extension InviteImageCarousel {

    private var pager: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, page in
                    Image(uiImage: page)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        //Must equal the flight image's expanded radii for the invisible handoff on page one.
                        .clipShape(.rect(
                            topLeadingRadius: SendInviteCard.imageRadius,
                            bottomLeadingRadius: SendInviteCard.imageBottomRadius,
                            bottomTrailingRadius: SendInviteCard.imageBottomRadius,
                            topTrailingRadius: SendInviteCard.imageRadius,
                            style: .continuous
                        ))
                        //Gap lives inside the cell (half per side) so the page pitch equals
                        //the viewport width and .paging lands every page centered.
                        .frame(width: size.width + Self.pageSpacing)
                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled() //Pages draw past the card gutter mid-scroll; the card mask cuts them at the true edge
        .modifier(PagedScrollStyle(
            scrolledPageID: $scrolledPageID,
            pageWidth: $pageWidth,
            scrollProgress: $scrollProgress,
            pageCount: images.count,
            dragDisabled: dragDisabled
        ))
        //Viewport = one page pitch, overhanging the slot by half the gap each side;
        //the outer frame re-clamps layout to the slot so the chrome anchors stay put.
        .frame(width: size.width + Self.pageSpacing)
        .frame(width: size.width)
    }

    private var backgroundBlur: some View {
        BackgroundBlur(
            image: images[min(scrolledPageID ?? 0, images.count - 1)],
            size: size,
            frames: [nameFrame],
            clipCornerRadius: SendInviteCard.imageBottomRadius,
            verticalInset: SendInviteCard.nameBlurInset
        )
    }

    //Two Texts (not one string) so the glyph layout matches the flight's "Meet " + name pair at the handoff.
    private var nameOverlay: some View {
        HStack(spacing: 0) {
            Text("Meet ")
            Text(name)
        }
        .font(.title(26))
        .foregroundStyle(Color.white)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.imageSpace)) } action: { nameFrame = $0 }
        .padding(.top, Self.nameTopInset)
        .padding(.leading, Self.nameLeadingInset)
    }
    
    
    private var optionsMenu: some View {
        Menu {
            if vm.event.hasChanges {
                Button("Clear Draft", systemImage: "trash", role: .destructive) {
                    // One animation owns the whole clear so every row cross-fades together.
                    withAnimation(.easeInOut(duration: 0.2)) { vm.deleteEventDefault() }
                }
            }
            Button("How Invites Work", systemImage: "info.circle") {
                showInfoScreen = true
            }
        } label: {
            InviteOptionsIcon()
                .padding(6)
                .shrinkPress()
                .contentShape(Circle())
        }
        .padding(-6)
        //Animates in parallel with the flight replica during a cancelled dismiss's spring-back,
        //so it is already at full opacity when the settle swap makes it the visible copy.
        .blurPop(visible: optionsVisible)
        .padding(.vertical, Self.nameTopInset)
        .padding(.horizontal, Self.nameLeadingInset)
        .sheet(isPresented: $showInfoScreen) { Text("Info screen here") }
    }
}
