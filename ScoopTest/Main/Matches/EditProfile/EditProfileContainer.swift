//
//  EditProfileContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

struct EditProfileContainer: View {
    
    @State var isView: Bool = true
    @State var vm: EditProfileViewModel
    
    
    var body: some View {
        let user: ProfileModel = ProfileModel(profile: vm.userManager.user)
        Group {
            if isView {
                ProfileView(vm: ProfileViewModel(profileModel: user, cacheManager: vm.cachManager))
                    .id(user.profile.imagePath ?? [])
                    .transition(.move(edge: .leading))
            } else {
                EditProfileView(vm: $vm)
                    .transition(.move(edge: .trailing))
            }
        }
        .overlay(alignment: .bottom) {
            EditProfileButton(isView: $isView)
                .padding(.bottom)
                .onTapGesture {
                    withAnimation{ isView.toggle()}
                }
        }
    }
}
