//
//  EditProfileContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

struct EditProfileContainer: View {
    @Environment(\.dismiss) private var dismiss
    @State var isEdit: Bool = false
    @State var vm: EditProfileViewModel
    let profileVM: ProfileViewModel
    @State var selectedImage: ImageSlot? = nil
    @State var showSavingScreen: Bool = false

    var body: some View {
        ZStack {
            if isEdit {
                NavigationStack { //EditProfileContainer is presented in a full screen
                    EditProfileView(vm: vm, selectedImage: $selectedImage)
                        .navigationDestination(for: EditProfileRoute.self, destination: destination)
                }
                .transition(.move(edge: .trailing))
            } else {
                ProfileView(vm: profileVM, profileImages: vm.images, mode: .ownProfile(draft: vm.draft))
                    .transition(.move(edge: .leading))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) { EditProfileButton(isEdit: $isEdit) }
        .overlay(alignment: .top) { editProfileHeader }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedImage) {imageEditScreen($0)}
        .task {if vm.images.isEmpty  {await vm.loadImages()}}
        .customLoadingScreen(isPresented: showSavingScreen, text: "Updating Profile")
    }
}

extension EditProfileContainer {
    private var editProfileHeader: some View {
        HStack {
            saveButton
            Spacer()
            DismissButton(type: .cross)
        }
        .padding(.horizontal, 20)
    }
    
    private var dismissButton: some View {
        
//        
//        ScoopButton(shape: Circle(), size: .large, action: {dismiss()}) {
//            Image(systemName: type.symbolName)
//        }
    }
    
    

    @ViewBuilder
    private var saveButton: some View {
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
                    .glassBackgroundIfAvailable(shape: .capsule)
                
            }
        }
    }
    
    private func imageEditScreen(_ slot: ImageSlot) -> some View {
        ProfileImagesEditing(importedImage: slot) {updatedImage in
            Task { try await vm.changeImage(image: updatedImage) }
        }
    }
    
    @ViewBuilder
    private func destination(for route: EditProfileRoute) -> some View {
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

enum EditProfileRoute: Hashable {
    case prompt(Int)
    case interests
    case textField(TextFieldOptions)
    case languages
    case option(OptionField)
    case height
    case nationality
    case lifestyle
    case myLifeAs
    case desiredAgeRange
}
