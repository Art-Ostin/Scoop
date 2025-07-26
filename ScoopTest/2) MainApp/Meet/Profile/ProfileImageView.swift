//
//  ProfileImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    
    @Binding var vm: ProfileViewModel
    @Binding var isInviting: Bool
    

    var body: some View {
        
        let stringURLs = vm.profile.imagePathURL
        
        GeometryReader { geo in
            TabView(selection: $vm.imageSelection) {
                
                if let urlString = stringURLs {
                    
                    let size = geo.size.width - 24
                    
                    ForEach (urlString.indices, id: \.self) {index in
                        let url = urlString[index]
                        if let url = URL(string: url) {
                            imageContainer(url: url, size: size, vm: $vm)
                                .tag(index)
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geo.size.width, height: 430)
            
        }
    }
}


//#Preview {
//    ProfileImageView(vm: .constant(ProfileViewModel(profile: CurrentUserStore.shared.user!)), isInviting: .constant(false))
//}

struct imageContainer: View {
    
    let url: URL
    let size: CGFloat

    @Binding var vm: ProfileViewModel
    
    var body: some View {
        
        AsyncImage(url: url) { Image in
            Image.resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()

        } placeholder: {
            ProgressView()
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
        .overlay(alignment: .bottomTrailing) {
            InviteButton(vm: vm)
                .padding(24)
        }
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
    }
    
}






//import SwiftUI
//
//struct ProfileImageView: View {
//    
//    @Binding var vm: ProfileViewModel
//    @Binding var isInviting: Bool
//    
//    let images = CurrentUserStore.shared.user?.imagePathURL
//
//    var body: some View {
//        GeometryReader { geo in
//            TabView(selection: $vm.imageSelection) {
//                ForEach(vm.profile.images.indices, id: \.self) {index in
//                    Image(vm.profile.images[index])
//                        .frame(height: 380)
//                        .overlay(alignment: .bottomTrailing) {
//                            InviteButton(vm: vm)
//                                .padding(24)
//                        }
//                        .tag(index)
//                }
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//            .frame(width: geo.size.width, height: 430)
//        }
//        
//    }
//}
//
//#Preview {
//    ProfileImageView(vm: .constant(ProfileViewModel()), isInviting: .constant(false))
//}
