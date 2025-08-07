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
    
    var body: some View {
        
        GeometryReader { geo in
            let size = geo.size.width - 16
            
            TabView(selection: $vm.imageSelection) {
                ForEach(images.indices, id: \.self) {index in
                    let image = images[index]
                    imageContainer(image: image, size: size) {
                        if vm.showInviteButton {
                            InviteButton(vm: vm)
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geo.size.width, height: size)
        }
        .task {
            images = await vm.dep.imageCache.fetchProfileImages(profiles: [vm.p])
        }
    }
}
