//
//  EditTextfield.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct OnboardingTextField: View  {
    @Bindable var vm: OnboardingViewModel
    let field: TextFieldOptions
    @State private var text = ""

    var body: some View {
        TextFieldGeneric(text: $text, field: field.title)
            .nextButton(isValid: text.count > 2, padding: 36) {
                vm.saveAndNextStep(kp: field.draftKeyPath, to: text)
            }
            .onAppear {
                if let draft = vm.draftProfile {
                    if field == .degree {
                        if !draft.degree.isEmpty {
                            text = draft.degree
                        }
                    }
                    if field == .hometown {
                        if !draft.hometown.isEmpty {
                            text = draft.hometown
                        }
                    }
                }
            }
    }
}

struct EditTextfield : View {
    //Injected
    @Bindable var vm: EditProfileViewModel
    let field: TextFieldOptions

    //Local view state
    @State private var showEmptyAlert = false

    var selection: Binding<String> {
        Binding {vm.draft[keyPath: field.keyPath]} set: {vm.set(field.key, field.keyPath, to: $0)}
    }
    
    var body: some View {
        TextFieldGeneric(text: selection, field: field.title)
            .checkBeforePop(invalid: selection.wrappedValue.isEmpty, triggerAlert: $showEmptyAlert)
            .customAlert(isPresented: $showEmptyAlert, message: "You can't leave '\(field.title.lowercased())' empty", showTwoButtons: false, onOK: { showEmptyAlert.toggle()})
    }
}




struct TextFieldGeneric: View {
    
    @Binding var text: String
    @FocusState var isFocused: Bool
    let field: String
    
    var body: some View {
        VStack(spacing: Spacing.titleGap)  {
            SignUpTitle(text: field)
            UnderlinedTextField(text: $text, placeholder: "Type \(field) here")
                .focused($isFocused)
        }
        .focusable()
        .padding(.horizontal)
        .onAppear {isFocused = true}
        .frame(maxHeight: .infinity, alignment:.top)
        .padding(.top, Spacing.clearance)
        .padding(.horizontal)
        .background(Color.appCanvas)
        .ignoresSafeArea(.keyboard)
    }
}



enum TextFieldOptions: CaseIterable {
    
    case degree, hometown, name
    
    var title: String {
        switch self {
        case .degree: "Degree"
        case .hometown: "Hometown"
        case .name: "Name"
        }
    }

    var key: UserProfile.Field {
        switch self {
        case .degree: .degree
        case .hometown: .hometown
        case .name: .name
        }
    }
    
    var keyPath: WritableKeyPath<UserProfile, String> {
        switch self {
        case .degree: \.degree
        case .hometown: \.hometown
        case .name: \.name
        }
    }
    
    var draftKeyPath: WritableKeyPath<DraftProfile, String> {
        switch self {
        case .degree: \.degree
        case .hometown: \.hometown
        default: \.degree
        }
    }
}

