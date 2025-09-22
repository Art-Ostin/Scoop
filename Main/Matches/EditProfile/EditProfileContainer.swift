//
//  EditProfileContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

struct EditProfileContainer: View {
    
    @Environment(\.dismiss) private var dismiss
    @State var isView: Bool = true
    @State var vm: EditProfileViewModel
    @State var selectedProfile: ProfileModel?
    
    var body: some View {
        Group {
            if let user = vm.draftUser, isView {
                ProfileView(vm: ProfileViewModel(profileModel: ProfileModel(profile: user), cacheManager: vm.cacheManager), selectedProfile: $selectedProfile) {
                    dismiss()
                }
                .transition(.move(edge: .leading))
            } else {
                EditProfileView(vm: vm)
                    .transition(.move(edge: .trailing))
            }
        }
        .id(vm.updatedImages.count)
        .task {
            await vm.assignSlots()
        }
        .overlay(alignment: .bottom) {
            EditProfileButton(isView: $isView)
                .padding(.bottom)
                .onTapGesture { withAnimation { isView.toggle() } }
        }
    }
}
