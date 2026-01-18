//
//  EditProfileContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

struct EditProfileContainer: View {
    @Environment(\.dismiss) private var dismiss
    @State var isEdit: Bool = true
    @State var vm: EditProfileViewModel
    let profileVM: ProfileViewModel
    @State var selectedProfile: ProfileModel?
    
    @State var dismissOffset: CGFloat? = nil
    @State var navigationPath: [EditProfileRoute] = []
    
    @State var selectedImage: ImageSlot? = nil
    
    var body: some View {
        ZStack {
            if isEdit {
                EditProfileView(vm: vm, navigationPath: $navigationPath, selectedImage: $selectedImage)
                    .transition(.move(edge: .leading))
            } else {
                ProfileView(vm: profileVM, profileImages: vm.images, selectedProfile: $selectedProfile, dismissOffset: $dismissOffset, draftProfile: vm.draft)
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if navigationPath.isEmpty {EditProfileButton(isEdit: $isEdit)}
        }
        .overlay(alignment: .top) {editAction}
        .fullScreenCover(item: $selectedImage) { localImage in
            ProfileImagesEditing(importedImage: localImage) {updatedImage in
                Task { try await vm.changeImage(image: updatedImage) }
            }
        }
        .task {await vm.assignSlots()}
    }
}

extension EditProfileContainer {
    private var editAction: some View {
        HStack {
            if navigationPath.isEmpty &&  vm.showSaveButton {
                Button {
                    Task {
                        try await vm.saveProfileChanges()
                        await MainActor.run {dismiss()}
                    }
                } label : {
                    Text("Save")
                        .font(.body(14, .bold))
                        .foregroundStyle(.accent)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .glassIfAvailable()
                }
            }
            Spacer()
            if navigationPath.isEmpty {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body(17, .bold))
                        .padding(5)
                        .glassIfAvailable(Circle())
                }
            }

        }
        .padding(.top, 6)
        .padding(.horizontal, 16)
    }
    
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.body(17, .bold))
                .padding(5)
                .glassIfAvailable(Circle())
                .padding(.top, 6)
                .padding(.trailing, 16)
        }
    }
    
    private var saveButton: some View {
        Button {
            Task { try await vm.saveProfileChanges() }
        } label : {
            Text("Save")
                .font(.body(14, .bold))
                .foregroundStyle(.accent)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .glassIfAvailable()
                .padding(.top, 6)
                .padding(.leading, 16)
        }
    }
}

/*
 .task {await vm.assignSlots()}
 */

/*
 .background(
     RoundedRectangle(cornerRadius: 20)
         .fill(Color.white)
         .shadow(color: .black.opacity(0.1), radius: 6, y: 5)
         .stroke(20, lineWidth: 1, color: .black)
 )
 */
