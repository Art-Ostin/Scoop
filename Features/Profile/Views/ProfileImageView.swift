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
            //If The images haven't been imported in time, load them up on the screen
            guard importedImages.isEmpty else { return }
            let loaded = await vm.loadImages()
            await MainActor.run {importedImages = loaded}
        }
        .measure(key: ImageSizeKey.self) {$0.frame(in: .global).width}
        .onPreferenceChange(ImageSizeKey.self) { screenWidth in
            imageSize = screenWidth - 12
        }
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
                        .id(index)
                        .frame(width: imageSize + 12)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
        .frame(height: imageSize)
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
            .customSubtleShadow(strength: selection == index ? 4 : 0)
            .onTapGesture { withAnimation(.easeInOut(duration: 0.4)) { self.selection = index } }
    }
}
