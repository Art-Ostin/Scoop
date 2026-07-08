//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

//The settled invite image: paged profile photos. Lives under the flight copy
//and takes over once it lands; the title chrome lives above the card.
struct InviteImageCarousel: View {

    let images: [UIImage]
    let size: CGSize
    @Binding var scrollProgress: Double

    @State private var scrolledPageID: Int?
    @State private var pageWidth: CGFloat = 0

    private static let pageSpacing: CGFloat = 4 //Visual gap between pages; built into each cell, never HStack spacing

    var body: some View {
        pager
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
                        .clipShape(.rect(
                            topLeadingRadius: SendInviteCard.imageRadius,
                            bottomLeadingRadius: SendInviteCard.imageBottomRadius,
                            bottomTrailingRadius: SendInviteCard.imageBottomRadius,
                            topTrailingRadius: SendInviteCard.imageRadius,
                            style: .continuous
                        ))
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
        .frame(width: size.width + Self.pageSpacing)
        .frame(width: size.width)
    }
}


struct HideSendInviteButton: View {
    
    let onBack: () -> Void
    
    var body: some View {
        ScoopButton(style: .clearGlass, shape: Capsule(style: .continuous), action: onBack) {
            HStack(spacing: 6) {
                Text("Hide")
                    .font(.body(13, .bold))

                Image(systemName: "chevron.up")
                    .offset(y: -0.5)
            }
            .font(.body(12, .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
