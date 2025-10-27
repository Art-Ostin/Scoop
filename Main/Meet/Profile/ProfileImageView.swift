//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    
    @State private var images: [UIImage] = []
    var preloaded: [UIImage]? = nil
    @State var selection: Int = 0
    @Binding var vm: ProfileViewModel
    let screenWidth: CGFloat

    let imagePadding: CGFloat = 8
    
    var body: some View {
            let safeScreenWidth = screenWidth.isFinite ? max(screenWidth, 0) : 0
            let imageSizeRaw = safeScreenWidth - imagePadding
            let imageSize = max(0, imageSizeRaw)
            VStack(spacing: 12) {
                profileImages(imageSize)
                    .frame(height: max(0, imageSize + 6))
                    .background (
                        GeometryReader { g in
                            Color.clear
                                .preference(key: ImageWidthKey.self, value: g.size.height - 6)
                        }
                    )
                imageScroller
                    .padding(.horizontal, 4)
            }
            .task {
            if let pre = preloaded {
                images = pre
            } else {
                images = await vm.loadImages()
            }
        }
    }
}

extension ProfileImageView {
    private func profileImages(_ size: CGFloat) -> some View {
        
            TabView(selection: $selection) {
                ForEach(images.indices, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .defaultImage(size, 16)
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                        .tag(index)
                        .indexViewStyle(.page(backgroundDisplayMode: .never))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
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
            .reportBottom(in: "profile", as: ScrollImageBottomValue.self)
        }
    }
}

