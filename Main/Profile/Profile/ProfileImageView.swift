//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

import SwiftUI

import Zoomable


struct ProfileImageView: View {
    
    @Bindable var vm: ProfileViewModel
    @Binding var showInvite: Bool
    @State private var selection = 0
    let imagePadding: CGFloat = 12
    @State var selectedImage = 0
    @State private var imageSize: CGFloat = 0
    let detailsOffset: CGFloat
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
            imageSize = screenWidth - imagePadding
        }
    }
}

extension ProfileImageView {

    private var profileImages: some View {
            TabView(selection: $selection) {
                ForEach(importedImages.indices, id: \.self) { index in
                        Image(uiImage: importedImages[index])
                            .resizable()
                            .defaultImage(imageSize, 16)
                            .tag(index)
                            .indexViewStyle(.page(backgroundDisplayMode: .never))
                            .pinchZoom()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !(vm.viewProfileType == .view) {
                    InviteButton(vm: vm, showInvite: $showInvite)
                        .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            //Apply the shadow after the frame so shadow not included in distance between views
            .frame(height: imageSize)
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
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
                            .shadow(color: .black.opacity(selection == index ? 0.2 : 0.15),
                                    radius: selection == index ? 3 : 1, y: selection == index ? 5 : 2)
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.4)) { self.selection = index} }
                            .stroke(10, lineWidth: selection == index ? 1 : 0, color: .accent)
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
