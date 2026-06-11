//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

import SwiftUI

import Zoomable


struct ProfileImageView: View {
    @Bindable var ui: ProfileUIState
    @Bindable var vm: ProfileViewModel
    //Present when the host drives a card→pager image morph (Events); nil elsewhere.
    @Environment(ProfileMorphState.self) private var morph: ProfileMorphState?
    @State private var selection: Int? = 0
    let imagePadding: CGFloat = 12
    @State private var imageSize: CGFloat = 0
    @State var importedImages: [UIImage]

    var body: some View {

        VStack(spacing: 24) {
            profileImages
            imageScroller
        }
        .task(id: importedImages.count) {
            //If the images haven't been imported in time, load them up on the
            //screen. A single image may be the morph seed (the tapped card photo) —
            //still fetch the full set; the seed stays page 0 so nothing jumps.
            guard importedImages.count <= 1 else { return }
            let loaded = await vm.loadImages()
            guard !loaded.isEmpty else { return }
            await MainActor.run {importedImages = loaded}
        }
        .getImageSize(imageSize: $imageSize, horizontalPadding: 6)
    }
}

extension ProfileImageView {

    private var profileImages: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(importedImages.indices, id: \.self) { index in
                    Image(uiImage: importedImages[index])
                        .resizable()
                        .defaultImage(imageSize, 16)
                        .pinchZoom()
                        //Hidden while the floating morph copy covers this frame.
                        .opacity(morph?.hiddenDestIndex == index ? 0 : 1)
                        .id(index)
                        .frame(width: imageSize + 12)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
        //The dismiss gesture owns the surface — paging pauses while it's live,
        //like the native zoom dismissal locking the content.
        .scrollDisabled(ui.isDismissDragging)
        .frame(height: imageSize)
        //The settled page image rect is this container inset by the 6pt gutters;
        //the morph reads it as the flight destination. Fires on real layout only —
        //drag transforms are invisible to geometry, so it never moves mid-drag.
        .onGeometryChange(for: CGRect.self) { geo in
            geo.frame(in: .global)
        } action: { rect in
            morph?.reportDestination(containerRect: rect)
        }
    }

    
    private var imageScroller : some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 48) {
                    ForEach(importedImages.indices, id: \.self) {index in
                        scrollImage(index: index)
                    }
                    ClearRectangle(size: 0)
                }
                .offset(x: 18) // Gives ScrollView padding initially
            }
            .frame(height: 60)
            .scrollDisabled(ui.isDismissDragging)
            .scrollClipDisabled() //
            .onChange(of: selection ?? 0) {oldIndex, newIndex in
                if oldIndex < 3 && newIndex == 3 {
                    withAnimation { proxy.scrollTo(newIndex, anchor: .leading) }
                }
                if oldIndex >= 3 && newIndex == 2 {
                    withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(newIndex, anchor: .trailing)}
                }
            }
        }
    }

    private func scrollImage(index: Int) -> some View {
        let image = importedImages[index]
        return Image(uiImage: image)
            .resizable()
            .defaultImage(60, 10)
            .customShadow(.card, strength: selection == index ? 4 : 0)
            .onTapGesture { withAnimation(.easeInOut(duration: 0.4)) { self.selection = index } }
    }
}
