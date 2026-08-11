//
//  EditProfileContainer.swift
//  Scoop
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI


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



struct EditProfileContainer: View {
    //Injected
    @Environment(\.dismiss) private var dismiss
    @State var vm: EditProfileViewModel
    let profileVM: ProfileViewModel

    //Local view state
    @State private var isEdit: Bool = false
    @State private var selectedImage: ImageSlot? = nil
    @State private var showSavingScreen: Bool = false
    @State private var isDetailsOpen = false //If details open and is edit, need to shrink the dismiss button
    @State private var path: [EditProfileRoute] = [] //Non-empty (an edit screen is pushed) hides certain views

    var body: some View {
        ZStack {
            if isEdit {
                editProfileView
            } else {
                profileView
            }
        }
        //Overlays
        .overlay(alignment: .bottom) { editProfileButton }
        .overlay(alignment: .top) { editProfileHeader }
                
        //Different Screens can go to
        .navigationDestination(for: EditProfileRoute.self, destination: destination)
        .fullScreenCover(item: $selectedImage) {editImageView($0)}
        .customLoadingScreen(isPresented: showSavingScreen, text: "Updating Profile")
    }
}


//Different Views
extension EditProfileContainer {
    
    private var editProfileView: some View {
        NavigationStack(path: $path) { // As EditProfile appears in full screen cover
            EditProfileView(vm: vm, selectedImage: $selectedImage, path: $path)
                .mask { Rectangle().ignoresSafeArea(edges: .vertical) } //Fixes bug
        }
        .transition(.move(edge: .trailing))
    }
    
    private var profileView: some View {
        ProfileContainer(vm: profileVM, profileImages: vm.images, mode: .ownProfile(draft: vm.draft))
            .mask { Rectangle().ignoresSafeArea(edges: .vertical) }
            .transition(.move(edge: .leading))
    }
    
    private func editImageView(_ slot: ImageSlot) -> some View {
        ProfileImageEditor(importedImage: slot) {updatedImage in
            Task { try await vm.changeImage(image: updatedImage) }
        }
    }
    
    private var editProfileButton: some View {
        EditProfileButton(isEdit: $isEdit, pathIsEmpty: path.isEmpty)
    }
}

//Header Components
extension EditProfileContainer {
    
    private var editProfileHeader: some View {
        HStack {
            saveButton
            Spacer()
            editProfileDismissButton
        }
        .padding(.horizontal, Spacing.md)
    }
    
    
    @ViewBuilder
    private var editProfileDismissButton: some View {
        let shrinkDismiss: Bool = !isEdit && isDetailsOpen
        
        ScoopButton(style: .clearGlass, shape: Circle(), size: .large) {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(shrinkDismiss ? .white : .black)
        }
        .offset(x: !isEdit ? -1 : 0, y: !isEdit ? -1 : 0)
        .offset(x: shrinkDismiss ? -2 : 0) // Put it in top corner if shrink mode
        .scaleEffect(shrinkDismiss ? 0.7 : !isEdit ? 0.7 :  1, anchor: .trailing)
        .animation(.move, value: shrinkDismiss)
        .opacity(path.isEmpty ? 1 : 0) //Hide the view when in an edit view
        .allowsHitTesting(path.isEmpty ? true  : false)
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
                    .padding(.vertical, Spacing.xs)
                    .glassEffectIfAvailable(shape: .capsule)
            }
            .opacity(path.isEmpty ? 1 : 0)
            .allowsHitTesting(path.isEmpty ? true : false)
        }
    }
}

//Destination Router
extension EditProfileContainer {
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
