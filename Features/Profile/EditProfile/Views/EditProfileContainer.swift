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
    @State private var showSavingScreen: Bool = false
    @State private var isDetailsOpen = false //If details open and is edit, need to shrink the dismiss button
    @State private var path: [EditProfileRoute] = [] //Non-empty (an edit screen is pushed) hides certain views
    @State private var saveLabelWidth: CGFloat = 0 //Measured, so the lens knows how wide to grow
    @State private var popGuard: (() -> Bool)? = nil //Set by a pushed screen that can refuse to be left
    @State private var isEditingImage = false //A photo editor is up; its drag is not the cover's

    var body: some View {
        ZStack {
            if isEdit {
                editProfileView
            } else {
                profileView
            }
        }
        //All three float above the zoom-presented photo editor, so each blur-pops away on
        //`isEditingImage` — the editor owns the screen from the moment the flight starts.
        .overlay(alignment: .bottom) { editProfileButton }
        .overlay(alignment: .topLeading) { leadingAction }
        .overlay(alignment: .topTrailing) { editProfileDismissButton }
        .interactiveDismissDisabled(!path.isEmpty || isEditingImage)
        .customLoadingScreen(isPresented: showSavingScreen, text: "Updating Profile")
    }
}


//Different Views
extension EditProfileContainer {
    
    private var editProfileView: some View {
        ZoomNavigationStack {
            NavigationStack(path: $path) { // As EditProfile appears in full screen cover
                EditProfileView(vm: vm, path: $path, isEditingImage: $isEditingImage)
                    .mask { Rectangle().ignoresSafeArea(edges: .vertical) } //Fixes bug
                    .navigationDestination(for: EditProfileRoute.self, destination: destination)
            }
        }
        .environment(ZoomPresentationHost?.none)
        .ignoresSafeArea()
        .transition(.move(edge: .trailing))
    }
    
    private var profileView: some View {
        ProfileContainer(vm: profileVM, profileImages: vm.images,
                         mode: .ownProfile(draft: vm.draft, showsSaveButton: vm.showSaveButton))
            .mask { Rectangle().ignoresSafeArea(edges: .vertical) }
            .transition(.move(edge: .leading))
    }
    
    @ViewBuilder
    private var editProfileButton: some View {
        let visible = path.isEmpty

        ViewAndEditProfileToggle(isEdit: $isEdit)
            .blur(radius: visible ? 0 : 8)
            .animation(visible ? nil : .quick, value: visible)
            .opacityPop(visible: visible)
            .allowsHitTesting(visible) //An opacity-0 view still takes taps
            .animation(visible ? .transition : .quick, value: visible)
            .blurPop(visible: !isEditingImage) //Out of the photo editor's way
            .ignoresSafeArea(.keyboard)
    }
}

//Header Components
extension EditProfileContainer {

    //The leading slot belongs to the flow, not to either screen inside it: ONE lens that reads
    //"Save" at the root and a back chevron in a field editor. Because the view survives the push,
    //the glass morphs between the two states instead of two separate buttons crossfading — which
    //is the whole point, and is impossible while the back button is the pushed screen's own.
    @ViewBuilder
    private var leadingAction: some View {
        let isRoot = path.isEmpty
        let visible = isRoot ? vm.showSaveButton : true
        let diameter = ButtonSize.large.size

        ScoopButton(style: .clearGlass, shape: Capsule()) {
            if isRoot { saveProfile() } else if popGuard?() ?? true { path.removeLast() }
        } label: {
            //Both labels stay mounted: the hidden one keeps reporting its width, and a
            //`.transition` here would unmount it and take the measurement with it.
            ZStack {
                Image(systemName: "chevron.left")
                    .font(.icon(14))
                    .opacity(isRoot ? 0 : 1)

                Text(visible ? "Save" : "")
                    .font(.body(15, .bold))
                    .foregroundStyle(.accent)
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { if $0 > 0 { saveLabelWidth = $0 } }
                    .opacity(isRoot ? 1 : 0)
            }
            .frame(width: isRoot ? saveLabelWidth + Spacing.sm * 2 : diameter,
                   height: isRoot ? ButtonSize.medium.size : diameter)
        }
        .animation(.expand, value: isRoot) //The morph
        .opacityPop(visible: visible, anchor: .leading) //Pinned to the edge, so it shrinks toward it
        .allowsHitTesting(visible) //opacityPop leaves it mounted at opacity 0
        .animation(isRoot ? .present : .expand, value: visible)
        .blurPop(visible: !isEditingImage, anchor: .leading) //Out of the photo editor's way
        .padding(.leading, Spacing.md)
        .offset(y: isEdit ? 0 : 6) //Fixes bug and lines up with title
    }

    private var editProfileDismissButton: some View {
        let shrinkDismiss: Bool = !isEdit && isDetailsOpen
        
        return ScoopButton(style: .clearGlass, shape: Circle(), size: .large) {
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
        .blurPop(visible: !isEditingImage, anchor: .trailing) //Out of the photo editor's way
        .padding(.trailing, Spacing.md)
    }
}

//Actions
extension EditProfileContainer {

    //Handed to EditProfileView's toolbar: the loading screen and the cover's dismissal are
    //this container's state, so the write stays here and only the button moves to the bar.
    private func saveProfile() {
        Task { @MainActor in
            if !vm.updatedImages.isEmpty {
                showSavingScreen = true
            }
            do {
                try await vm.saveProfileChanges()
                dismiss()
            } catch {
                showSavingScreen = false // TODO: surface the failure via InAppNotificationCenter
            }
        }
    }
}

//Destination Router
extension EditProfileContainer {
    @ViewBuilder
    private func destination(for route: EditProfileRoute) -> some View {
        Group {
            switch route {
            case .prompt(let index):     EditPrompt(vm: vm, promptIndex: index)
            case .interests:             EditInterests(vm: vm)
            case .textField(let field):  EditTextfield(vm: vm, field: field)
            case .option(let field):     EditOption(vm: vm, field: field)
            case .height:                EditHeight(vm: vm)
            case .nationality:           EditNationality(vm: vm)
            case .lifestyle:             EditLifestyle(vm: vm)
            case .myLifeAs:              EditMyMedia(vm: vm)
            case .languages:             EditLanguages(vm: vm)
            case .desiredAgeRange:       EditPreferredYears(vm: vm)
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(\.popGuard, $popGuard)
    }
}
