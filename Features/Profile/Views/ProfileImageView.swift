//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

import SwiftUI


struct ProfileImageView: View {

    @Environment(ProfileMorphState.self) private var morph: ProfileMorphState?
    @State private var imageSize: CGFloat = 0
    @State private var selection: Int? = 0
    @State var scrollPosition = ScrollPosition()

    let disableScroll: Bool
    let importedImages: [UIImage]
    
    var body: some View {
        
        VStack(spacing: 24) {
            largeImageScrollView
            imageScroller
        }
        .getImageSize(imageSize: $imageSize, horizontalPadding: 6)
        
    }
}

//All Logic for large images
extension ProfileImageView {
    
    private var largeImageScrollView: some View {
        HorizontalScrollView {
            ForEach(importedImages.indices, id: \.self) { index in
                largeImage(index: index)
            }
        }
        .frame(height: imageSize)
        .scrollDisabled(disableScroll)
        .scrollPosition(id: $selection)
        .onGeometryChange(for: CGRect.self) {$0.frame(in: .global)} action: { rect in
            morph?.reportDestination(containerRect: rect)
        }
    }
    
    private func largeImage(index: Int) -> some View {
        Image(uiImage: importedImages[index])
            .defaultImage(imageSize, 16)
            .pinchZoom()
            .opacity(morph?.hiddenDestIndex == index ? 0 : 1) //Hidden while the floating morph copy covers this frame.
            .horizontalScrollSlot(id: index)
    }
}

//All Logic for the imageScrollView
extension ProfileImageView {
    
    private var imageScroller : some View {
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
            .scrollPosition($scrollPosition)
            .scrollDisabled(disableScroll)
            .scrollClipDisabled() //
            .onChange(of: selection ?? 0) {scrollToImage(oldIndex: $0, newIndex: $1)}
    }
    
    private func scrollImage(index: Int) -> some View {
        let image = importedImages[index]
        return Image(uiImage: image)
            .defaultImage(60, 10)
            .customShadow(.card, strength: selection == index ? 4 : 0)
            .onTapGesture { withAnimation(.easeInOut(duration: 0.4)) { self.selection = index } }
    }

    private func scrollToImage(oldIndex: Int, newIndex: Int) {
        if oldIndex < 3 && newIndex == 3 {
            withAnimation { scrollPosition.scrollTo(id: newIndex, anchor: .leading) }
        }
        if oldIndex >= 3 && newIndex == 2 {
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollPosition.scrollTo(id: newIndex, anchor: .trailing)
            }
        }
    }
    
}

