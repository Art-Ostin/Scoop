//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    
    @Binding var vm: ProfileViewModel
    @State private var images: [UIImage] = []
    @State var selection: Int = 0

    var body: some View {
        VStack {
            mainImages
            imageScroller
        }
        .task {
            print("got all user's images")
            images = await vm.dep.cacheManager.loadProfileImages([vm.p])
        }
    }
}

extension ProfileImageView {
    
    private var mainImages: some View {
        GeometryReader { geo in
            let size = geo.size.width - 16
            
            TabView(selection: $selection) {
                ForEach(images.indices, id: \.self) {index in
                    let image = images[index]
                    imageContainer(image: image, size: size) {
                        InviteButton(vm: $vm)
                    }.tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geo.size.width, height: size)
        }
    }
    
    private var imageScroller : some View {
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 48) {
                    ForEach(images.indices, id: \.self) {index in
                        let image = images[index]
                        imageContainer(image: image, size: 60, shadow: self.selection == index ? 5 : 0) {
                        }
                    }
                }
            } .onChange(of: selection) {oldIndex, newIndex in
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
