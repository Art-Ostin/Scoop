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
    
    var body: some View {
        Group {
            if isView {
                ProfileView(vm: ProfileViewModel(profileModel: ProfileModel(profile: vm.draftUser), cacheManager: vm.cacheManager), preloadedImages: vm.images){
                    dismiss()
                }
                .transition(.move(edge: .leading))

            } else {
                EditProfileView(vm: $vm)
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
                .onTapGesture {
                    withAnimation{ isView.toggle()}
                }
        }
    }
}
