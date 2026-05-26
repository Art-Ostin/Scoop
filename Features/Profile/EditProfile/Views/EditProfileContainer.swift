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
    @State var selectedImage: ImageSlot? = nil
    @State var showSavingScreen: Bool = false

    var body: some View {
        ZStack {
            if isEdit {
                EditProfileView(vm: vm, selectedImage: $selectedImage)
                    .transition(.move(edge: .leading))
            } else {
                ProfileView(
                    vm: profileVM,
                    profileImages: vm.images,
                    mode: .ownProfile(draft: vm.draft)
                )
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) { EditProfileButton(isEdit: $isEdit) }
        .overlay(alignment: .top) { editAction }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: EditProfileRoute.self) { route in
            subScreen(for: route)
        }
        .fullScreenCover(item: $selectedImage) {localImage in
            ProfileImagesEditing(importedImage: localImage) {updatedImage in
                Task { try await vm.changeImage(image: updatedImage) }
            }
        }
        .task {
            if vm.images.isEmpty  {
                await vm.loadImages()
            }
        }
        .customLoadingScreen(isPresented: showSavingScreen, text: "Updating Profile")
    }

    @ViewBuilder
    private func subScreen(for route: EditProfileRoute) -> some View {
        switch route {
        case .prompt(let index):     EditPrompt(vm: vm, promptIndex: index)
        case .interests:             EditInterests(vm: vm)
        case .textField(let field):  EditTextfield(vm: vm, field: field)
        case .option(let field):     EditOption(vm: vm, field: field)
        case .height:                EditHeight(vm: vm)
        case .nationality:           EditNationality(vm: vm)
        case .lifestyle:             EditLifestyle(vm: vm)
        case .myLifeAs:              EditMyLifeAs(vm: vm)
        case .languages:             EditLanguages(vm: vm)
        case .desiredAgeRange:       EditPreferredYears(vm: vm)
        }
    }
}

extension EditProfileContainer {
    private var editAction: some View {
        HStack {
            if vm.showSaveButton {
                Button {
                    if !vm.updatedImages.isEmpty {
                        showSavingScreen = true
                    }
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
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body(17, .bold))
                    .padding(5)
                    .glassIfAvailable(Circle())
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
