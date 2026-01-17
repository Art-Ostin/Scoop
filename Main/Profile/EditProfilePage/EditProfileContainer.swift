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
    let profileVM: ProfileViewModel
    @State var selectedProfile: ProfileModel?
    
    @Binding var images: [UIImage]
    @State var dismissOffset: CGFloat? = nil
    
    var body: some View {
        Group {
            if isView {
                ProfileView(vm: profileVM, profileImages: images, selectedProfile: $selectedProfile, dismissOffset: $dismissOffset)
                    .transition(.move(edge: .leading))
            } else {
                EditProfileView(vm: vm)
                    .transition(.move(edge: .trailing))
            }
        }
        .id(vm.updatedImages.count)
        .task {await vm.assignSlots()}
        .overlay(alignment: .bottom) {EditProfileButton(isView: $isView)}
        .toolbar {CloseToolBar(isLeading: false)}
        .toolbar {ToolbarItem(placement: .topBarLeading) {Button("SAVE") { if vm.showSaveButton {Task {try await vm.saveProfileChanges()}}}}}
    }
}

/*
 DraftProfileView(vm: ProfileViewModel(profileModel: ProfileModel(profile: vm.user), cacheManager: vm.cacheManager))
 */
