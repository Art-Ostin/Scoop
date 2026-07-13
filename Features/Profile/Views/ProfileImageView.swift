//
//  ProfileImageView.swift
//  Scoop
//
//  Created by Art Ostin on 25/06/2025.

import SwiftUI
import Zoomable


struct ProfileImageView: View {

    //Injected
    @Environment(ProfileMorphState.self) private var morph: ProfileMorphState?
    let disableScroll: Bool
    let images: [UIImage]
    var selectedIndex: Binding<Int>? = nil //Reports the settled page so the invite card can zoom from it

    //Local view state
    @State private var scrollProgress: Double = 0
    @State private var pagerPosition = ScrollPosition()
    @State private var scrollPosition = ScrollPosition()
    @State private var zoomedPhoto: PhotoViewerSource?

    //trackScrollProgress reports the page index as a float; the settled page drives the thumb strip.
    private var selection: Int { Int(scrollProgress.rounded()) }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            imageCarousel
            imageScroller
        }
        .onChange(of: selection) { _, new in selectedIndex?.wrappedValue = new }
    }
}

//The full-width image pager (profile-morph destination)
extension ProfileImageView {

    private var imageCarousel: some View {
        ImageCarousel(
            images: images,
            hPadding: 8,
            topRadius: CornerRadius.image,
            bottomRadius: CornerRadius.image,
            aspectRatio: .card,
            onImageTap: { zoomedPhoto = PhotoViewerSource(id: $0) },
            scrollProgress: $scrollProgress,
            scrollPosition: $pagerPosition,
        )
        .scrollDisabled(disableScroll)
        .onGeometryChange(for: CGRect.self) {$0.frame(in: .global)} action: { rect in
            morph?.reportDestination(containerRect: rect)
        }
        .fullScreenCover(item: $zoomedPhoto) { PhotoZoomViewer(images: images, startIndex: $0.id) }
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

//MARK: - Full-screen photo viewer

//A photo id wrapper so fullScreenCover(item:) can seed the viewer at the tapped index.
private struct PhotoViewerSource: Identifiable { let id: Int }

//Immersive full-screen photo viewer: pinch / double-tap to zoom (ryohey/Zoomable),
//tappable dots to switch photos. Presented as its own modal, so the zoom gestures are
//isolated from the profile pager and the reverse-zoom dismiss drag underneath it.
struct PhotoZoomViewer: View {

    //Injected
    let images: [UIImage]

    //Local view state
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int

    init(images: [UIImage], startIndex: Int) {
        self.images = images
        _index = State(initialValue: min(max(startIndex, 0), max(images.count - 1, 0)))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() //Immersive lightbox backdrop.

            if images.indices.contains(index) {
                Image(uiImage: images[index])
                    .resizable()
                    .scaledToFit()
                    .zoomable(minZoomScale: 1, maxZoomScale: 5)
                    .id(index) //Remount on switch → zoom resets to fit.
            }
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .overlay(alignment: .bottom) { photoDots }
    }
}

extension PhotoZoomViewer {

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.icon(15, .semibold))
                .foregroundStyle(Color.white)
                .padding(Spacing.sm)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(Spacing.margin)
    }

    //Tappable dots switch photos without a swipe gesture, so nothing competes with zoom pan.
    @ViewBuilder
    private var photoDots: some View {
        if images.count > 1 {
            HStack(spacing: Spacing.xs) {
                ForEach(images.indices, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(i == index ? 1 : 0.4))
                        .frame(width: 7, height: 7) //Geometry: fixed dot size, not a spacing rhythm
                        .onTapGesture { withAnimation(.toggle) { index = i } }
                }
            }
            .padding(Spacing.sm)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, Spacing.clearance)
        }
    }
}
