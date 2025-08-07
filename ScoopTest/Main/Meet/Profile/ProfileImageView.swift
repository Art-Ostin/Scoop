//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    
    @Binding var vm: ProfileViewModel
    
    var body: some View {

        let images =  vm.dep.imageCache.fetchProfileImages(profiles: [vm.p])
        
        GeometryReader { geo in
            
            let size = geo.size.width - 16
            
            TabView(selection: $vm.imageSelection) {
                
                ForEach(images.indices, id: \.self) {index in
                    
                    let image = images[index]
                    
                    imageContainer(uiImage: image, size: size) {
                        if vm.showInviteButton {
                            InviteButton(vm: vm)
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geo.size.width, height: size + 16)
        }
    }
}

struct imageContainer<Overlay: View>: View {
    
    let image: UIImage
    let size: CGFloat
    let shadow: CGFloat
    @ViewBuilder var overlay: () -> Overlay
    
    init(image: UIImage, size: CGFloat, shadow: CGFloat = 5, @ViewBuilder overlay: @escaping () -> Overlay = {EmptyView()}) {
        self.image = image
        self.size = size
        self.shadow = shadow
        self.overlay = overlay
    }
    
    var body: some View {
        
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: shadow)
            .overlay(alignment: .bottomTrailing) {
                overlay()
                    .padding(24)
            }
    }
}
