//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    
    let proxy: GeometryProxy
    @Binding var vm: ProfileViewModel
    @State private var images: [UIImage] = []
    var preloaded: [UIImage]? = nil
    @State var selection: Int = 0
    
    @Binding var selectedProfile: ProfileModel?
    @Binding var currentOffset: CGFloat
    @Binding var endingOffset: CGFloat
    
    var  width: CGFloat { proxy.size.width - 8 }

    var body: some View {
        
        VStack(spacing: 24) {
            
            profileImages
                .frame(height: width + 6)
            
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
    
    private var profileImages : some View {
        TabView(selection: $selection) {
            ForEach(images.indices, id: \.self) { index in
                Image(uiImage: images[index])
                    .resizable()
                    .defaultImage(width, 16)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                    .tag(index)
                    .background (
                        GeometryReader { proxy  in
                            Color.clear
                                .preference(key: MainImageBottomValue.self, value: proxy.frame(in: .global).maxY)
                        }
                    )
            }
        }
        .overlay(alignment: .topLeading) {
            HStack {
                Text(vm.profileModel.profile.name)

                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44, alignment: .center)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if endingOffset != 0 {
                            withAnimation(.spring(duration: 0.2)) {
                                selectedProfile = nil
                            }
                        }
                    }
                    .font(.body(20, .bold))
            }
            .font(.body(24, .bold))
            .foregroundStyle(.white)
            .padding()
            .opacity(
                titleOpacity(currentOffset: currentOffset, endingOffset: endingOffset)
            )

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
        }
    }
    
    func titleOpacity(currentOffset: CGFloat, endingOffset: CGFloat) -> Double {
        if endingOffset != 0 {
            return (1 - (abs(currentOffset) / 100))
        } else if currentOffset < -200  {
            return (0  + (abs(currentOffset + 200) / 100))
        } else {
            return 0
        }
    }
    
    /*
     if endingOffset == 0 {
         let d = min(abs(currentOffset), 300)
         return max(84.0 - (84.0 * d / 300.0), 0)
     } else {
         let d = min(abs(currentOffset), 300)
         return min(0 + (84.0 * d / 300.0), 84.0)
     }
     */

    
    
}

/*
 .gesture(
     MagnificationGesture()
         .onChanged { imageZoom = $0 }
         .onEnded {_ in withAnimation(.spring) {imageZoom = 1} }
 )
 .frame(height: imageZoom <= 1 ? width + 12 : size.height, alignment: .top)
 .scaleEffect(imageZoom)

 */


/*
 .overlay(alignment: .bottomTrailing) {
     InviteButton(vm: $vm)
         .padding(16)
         .zIndex(30)
 }
 */

