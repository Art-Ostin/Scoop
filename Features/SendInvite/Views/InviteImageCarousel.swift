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
    @Binding var scrollProgress: Double
    let onBack: () -> Void

    @State private var scrolledPageID: Int?
    @State private var pageWidth: CGFloat = 0
    @State private var nameFrame: CGRect = .zero
    @State private var hideButtonHeight: CGFloat = 0

    private static let imageSpace = "InviteImageCarousel.image"
    private static let pageSpacing: CGFloat = 4 //Visual gap between pages; built into each cell, never HStack spacing

    var body: some View {
        pager
            .overlay { backgroundBlur }
//            .overlay(alignment: .topLeading) { InviteBackButton(action: onBack) }
            .overlay(alignment: .topLeading) { nameOverlay }
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
            pageCount: images.count
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
        .padding(.top, 12)
        .padding(.leading, SendInviteContainer.contentPadding)
        .padding(.bottom, SendInviteCard.chromeBottomPadding)
    }
}
