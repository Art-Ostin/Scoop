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
    var preloaded: [UIImage]? = nil
    @State var selection: Int = 0

    var body: some View {
        VStack(spacing: 36) {
            mainImages
            imageScroller
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
    
    private var mainImages: some View {
        GeometryReader { geo in
            let size = geo.size.width - 12
                TabView(selection: $selection) {
                ForEach(images.indices, id: \.self) {index in
                    let image = images[index]
                    imageContainer(image: image, size: size) {
                        if !(vm.viewProfileType == .view) {InviteButton(vm: $vm) }
                    }.tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geo.size.width, height: size)
        }
        .frame(height: UIScreen.main.bounds.width - 12)
    }

    private var imageScroller : some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 48) {
                    ForEach(images.indices, id: \.self) {index in
                        let image = images[index]
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: selection == index ? .black.opacity(0.4) : .clear, radius: 2, x: 0, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.accent, lineWidth: self.selection == index ? 1 : 0)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.9)) { self.selection = index}
                            }
                    }
                    .padding(.horizontal)
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
