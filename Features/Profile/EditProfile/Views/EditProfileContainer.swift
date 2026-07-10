//
//  EditProfileContainer.swift
//  Scoop
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

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
                NavigationStack(path: $path) {
                    EditProfileView(vm: vm, selectedImage: $selectedImage)
//                        .clipped()  //Fixes bug of content over extending
                        .transition(.move(edge: .trailing))
                }
            } else {
                ProfileContainer(vm: profileVM, profileImages: vm.images, mode: .ownProfile(draft: vm.draft))
//                    .clipped() //Fixes bug of content over extending
                    .transition(.move(edge: .leading))
            }
        }
        .navigationDestination(for: EditProfileRoute.self, destination: destination)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) { EditProfileButton(isEdit: $isEdit, pathIsEmpty: path.isEmpty) }
        .overlay(alignment: .top) { editProfileHeader }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedImage) {imageEditScreen($0)}
        .task {if vm.images.isEmpty  {await vm.loadImages()}}
        .customLoadingScreen(isPresented: showSavingScreen, text: "Updating Profile")
        .onPreferenceChange(ProfileDetailsOpenKey.self) { isDetailsOpen = $0 }
    }
}

extension EditProfileContainer {
    private var editProfileHeader: some View {
        HStack {
            editProfileDismissButton
            Spacer()
            saveButton
        }
        .padding(.horizontal, 16)
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
        .scaleEffect(shrinkDismiss ? 0.7 : !isEdit ? 0.7 :  1, anchor: .topLeading)
        .animation(.snappy, value: shrinkDismiss)
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
    
    private func imageEditScreen(_ slot: ImageSlot) -> some View {
        ProfileImageEditor(importedImage: slot) {updatedImage in
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

struct ProfileDetailsOpenKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
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
