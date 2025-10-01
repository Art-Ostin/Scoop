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
    
    let imagePadding: CGFloat = 8

    var body: some View {
        
        
        GeometryReader { proxy in
            let imageSize = proxy.size.width - imagePadding
            VStack(spacing: 24) {
                
                profileImages(imageSize)
                    .frame(height: imageSize + 6)
                
                imageScroller
                    .frame(height: 66)
                    .padding(.horizontal, 4)
            }
            .preference(key: ImageWidthKey.self, value: imageSize)
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
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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
                            .shadow(color: .black.opacity(selection == index ? 0.25 : 0.15),
                                    radius: selection == index ? 2 : 1, y: selection == index ? 4 : 2)
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.8)) { self.selection = index} }
                            .stroke(10, lineWidth: selection == index ? 1 : 0, color: .accent)
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


/*
 Image(systemName: "chevron.down")
     .foregroundStyle(.white)
     .frame(width: 44, height: 44, alignment: .center)
     .contentShape(Rectangle())
     .onTapGesture {
         if detailsOpen {selectedProfile = nil}
     }
     .font(.body(20, .bold))
 */
