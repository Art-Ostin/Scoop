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
    
    let stringURLs = EditProfileViewModel.instance.user?.imagePathURL
    
    var body: some View {
        GeometryReader { geo in
            TabView(selection: $vm.imageSelection) {
                
                if let urlString = stringURLs {
                    
                    ForEach (urlString, id: \.self) {stringUrls in
                        
                        if let url = URL(string: stringUrls) {
                            imageContainer(url: url, vm: $vm)
                            .tag(urlString)
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: geo.size.width, height: 430)
            
        }
    }
}


#Preview {
    ProfileImageView(vm: .constant(ProfileViewModel()), isInviting: .constant(false))
}

struct imageContainer: View {
    
    let url: URL
    @Binding var vm: ProfileViewModel
    
    var body: some View {
        
        AsyncImage(url: url) { Image in
            Image.resizable().scaledToFit()

        } placeholder: {
            ProgressView()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
        .overlay(alignment: .bottomTrailing) {
            InviteButton(vm: vm)
                .padding(24)
        }
        
        
    }
    
}






//import SwiftUI
//
//struct ProfileImageView: View {
//    
//    @Binding var vm: ProfileViewModel
//    @Binding var isInviting: Bool
//    
//    let images = EditProfileViewModel.instance.user?.imagePathURL
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
