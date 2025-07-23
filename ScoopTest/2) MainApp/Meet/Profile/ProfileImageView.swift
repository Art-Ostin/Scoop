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
    
    let images = EditProfileViewModel.instance.user?.imagePathURL

    var body: some View {
        GeometryReader { geo in
            TabView(selection: $vm.imageSelection) {
                ForEach(vm.profile.images.indices, id: \.self) {index in
                    Image(vm.profile.images[index])
                        .frame(height: 380)
                        .overlay(alignment: .bottomTrailing) {
                            InviteButton(vm: vm)
                                .padding(24)
                        }
                        .tag(index)
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
