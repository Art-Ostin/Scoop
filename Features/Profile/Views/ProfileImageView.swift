//
//  ProfileImageView.swift
//  Scoop
//
//  Created by Art Ostin on 25/06/2025.

import SwiftUI


struct ProfileImageView: View {

    let disableScroll: Bool
    let images: [UIImage]
    var selectedIndex: Binding<Int>? = nil //Reports the settled page used to seed Quick Invite.

    //Local view state
    @State private var scrollProgress: Double = 0
    @State private var pagerPosition = ScrollPosition()
    @State private var scrollPosition = ScrollPosition()

    //trackScrollProgress reports the page index as a float; the settled page drives the thumb strip.
    private var selection: Int { Int(scrollProgress.rounded()) }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ImageCarousel(horizontalPadding: 8, aspectRatio: 1.05)
                .padding(.top, 12)
            imageScroller
        }
        .onChange(of: selection) { _, new in selectedIndex?.wrappedValue = new }
    }
}

//The thumbnail strip that mirrors and drives the pager
extension ProfileImageView {

    private var imageScroller : some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xxl) {
                    ForEach(images.indices, id: \.self) {index in
                        scrollImage(index: index)
                    }
                }
            }
            .contentMargins(.horizontal, Spacing.lg)
            .frame(height: 60)
            .scrollPosition($scrollPosition)
            .scrollDisabled(disableScroll)
            .scrollClipDisabled() //
            .onChange(of: selection) {scrollToImage(oldIndex: $0, newIndex: $1)}
    }

    private func scrollImage(index: Int) -> some View {
        SmallImage(image: images[index], size: 60)
            .shadow(.image, strength: selection == index ? 1 : 0)
            .onTapGesture { withAnimation(.move) { pagerPosition.scrollTo(id: index) } }
    }

    private func scrollToImage(oldIndex: Int, newIndex: Int) {
        if oldIndex < 3 && newIndex == 3 {
            withAnimation(.move) { scrollPosition.scrollTo(id: newIndex, anchor: .leading) }
        }
        if oldIndex >= 3 && newIndex == 2 {
            withAnimation(.move) {
                scrollPosition.scrollTo(id: newIndex, anchor: .trailing)
            }
        }
    }
}
