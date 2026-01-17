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
    
    @Binding var images: [UIImage]
    @State var dismissOffset: CGFloat? = nil
    
    @State var navigationPath: [EditProfileRoute] = []
    
    
    var body: some View {
        Group {
            if isEdit {
                EditProfileView(vm: vm, navigationPath: $navigationPath)
            } else {
                ProfileView(vm: profileVM, profileImages: images, selectedProfile: $selectedProfile, dismissOffset: $dismissOffset, isUserProfile: true)
            }
        }
        .transition(.move(edge: .leading))
        .id(vm.updatedImages.count)
        .task {await vm.assignSlots()}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if navigationPath.isEmpty {EditProfileButton(isEdit: $isEdit)}
        }
        .overlay(alignment: .top) {editAction}
    }
}

extension EditProfileContainer {
    private var editAction: some View {
        HStack {
            if navigationPath.isEmpty &&  vm.showSaveButton {
                Button {
                    Task { try await vm.saveProfileChanges() }
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
 .background(
     RoundedRectangle(cornerRadius: 20)
         .fill(Color.white)
         .shadow(color: .black.opacity(0.1), radius: 6, y: 5)
         .stroke(20, lineWidth: 1, color: .black)
 )
 */
