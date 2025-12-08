//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    
    @Bindable var vm: ProfileViewModel
    @State private var images: [UIImage] = []
    var preloaded: [UIImage]? = nil
    @State private var selection = 0
    let imagePadding: CGFloat = 12
    @State private var imageSize: CGFloat = 0
    
    var body: some View {
        
        
        profileImages

        
        VStack(spacing: 12) {
            imageScroller
        }
        .task {
            if let pre = preloaded {
                images = pre
            } else {
                images = await vm.loadImages()
            }
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
            ForEach(images.indices, id: \.self) { index in
                Image(uiImage: images[index])
                    .resizable()
                    .defaultImage(imageSize)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                    .tag(index)
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: imageSize + 6, alignment: .top)
        .background(Color.blue)
        .measure(key: ImageSectionBottom.self) {geo in
              geo.frame(in: .named("profile")).maxY //Gets bottom of this view
            }
    }
    
    private var imageScroller : some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 48) {
                    ForEach(images.indices, id: \.self) {index in
                        let image = images[index]
                        Image(uiImage: image)
                            .resizable()
                            .defaultImage(60, 10)
                            .shadow(color: .black.opacity(selection == index ? 0.2 : 0.15),
                                    radius: selection == index ? 3 : 1, y: selection == index ? 5 : 2)
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.8)) { self.selection = index} }
                            .stroke(10, lineWidth: selection == index ? 1.5 : 0, color: .accent)
                            .frame(height: 84)
                    }
                    ClearRectangle(size: 16)
                }
            }
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
 .measure(key: ImageSectionBottom.self) { geo in
//                geo.frame(in: .named("profile")).maxY //Gets bottom of this view
//            }
//            .ignoresSafeArea(edges: .all)
 */
