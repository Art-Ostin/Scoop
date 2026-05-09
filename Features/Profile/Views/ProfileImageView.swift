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
    @State private var selection = 0
    let imagePadding: CGFloat = 12
    @State private var imageSize: CGFloat = 0
    @State var importedImages: [UIImage]
    
    var body: some View {
        
        VStack(spacing: 24, ) {
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
            imageSize = screenWidth - 16
        }
    }
}

extension ProfileImageView {


    private var profileImages: some View {
        Image(uiImage: importedImages.first ?? UIImage())
            .resizable()
            .defaultImage(imageSize, 16)
//            .tag(index)
            .pinchZoom()
//            .frame(height: imageSize + 12)
    }

    
    private var imageScroller : some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 48) {
                    ForEach(importedImages.indices, id: \.self) {index in
                        let image = importedImages[index]
                        Image(uiImage: image)
                            .resizable()
                            .defaultImage(60, 10)
                            .customSubtleShadow(strength: selection == index ? 4 : 0)
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.4)) { self.selection = index } }
                    }
                    ClearRectangle(size: 0)
                }
                .offset(x: 18) // Gives ScrollView padding initially
            }
            .frame(height: 60)
            .scrollClipDisabled() //
            .onChange(of: selection) {oldIndex, newIndex in
                if oldIndex < 3 && newIndex == 3 {
                    withAnimation { proxy.scrollTo(newIndex, anchor: .leading) }
                }
                if oldIndex >= 3 && newIndex == 2 {
                    withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(newIndex, anchor: .trailing)}
                }
            }
        }
    }
}

/*
 TabView(selection: $selection) {
     ForEach(importedImages.indices, id: \.self) { index in
             Image(uiImage: importedImages[index])
                 .resizable()
                 .defaultImage(displayedImageSize, 16)
                 .tag(index)
                 .pinchZoom()
     }
 }
 .border(.red, width: 2)
 .frame(height: displayedImageSize)
 .indexViewStyle(.page(backgroundDisplayMode: .never))
 .tabViewStyle(.page(indexDisplayMode: .never))
 .animation(.spring(response: 0.32, dampingFraction: 0.86), value: ui.detailOpen)
 //Apply the shadow after the frame so shadow not included in distance between views

 TabView(selection: $selection) {
     ForEach(importedImages.indices, id: \.self) { index in
             Image(uiImage: importedImages[index])
                 .resizable()
                 .defaultImage(displayedImageSize, 16)
                 .tag(index)
                 .pinchZoom()
     }
 }
 .border(.red, width: 2)
 .frame(height: displayedImageSize)
 .indexViewStyle(.page(backgroundDisplayMode: .never))
 .tabViewStyle(.page(indexDisplayMode: .never))
 .animation(.spring(response: 0.32, dampingFraction: 0.86), value: ui.detailOpen)
 //Apply the shadow after the frame so shadow not included in distance between views

 
 */
