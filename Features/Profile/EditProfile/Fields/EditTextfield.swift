//
//  TextFieldEdit.swift
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
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: EditProfileViewModel
    let field: TextFieldOptions

    //Local view state
    @State private var showEmptyAlert = false

    var selection: Binding<String> {
        Binding {vm.draft[keyPath: field.keyPath]} set: {vm.set(field.key, field.keyPath, to: $0)}
    }
    
    var body: some View {
        TextFieldGeneric(text: selection, field: field.title)
            .closeAndCheckNavButton(check: selection.wrappedValue.isEmpty, triggerAlert: $showEmptyAlert)
            .customAlert(isPresented: $showEmptyAlert, message: "You can't leave '\(field.title.lowercased())' empty", showTwoButtons: false, onOK: { showEmptyAlert.toggle()})
    }
}




struct TextFieldGeneric: View {
    
    @Binding var text: String
    @FocusState var isFocused: Bool
    let field: String
    
    var body: some View {
        VStack(spacing: 72)  {
            SignUpTitle(text: field)
            customTextField
        }
        .focusable()
        .padding(.horizontal)
        .onAppear {isFocused = true}
        .frame(maxHeight: .infinity, alignment:.top)
        .padding(.top, 96)
        .padding(.horizontal)
        .background(Color.appCanvas)
        .ignoresSafeArea(.keyboard)
    }
}



extension TextFieldGeneric {
    
     var customTextField: some View  {
        VStack {
            TextField("Type \(field) here", text: $text)
                .frame(maxWidth: .infinity)
                .font(.body(24,.medium))
                .focused($isFocused)
                .autocorrectionDisabled(true)
                .tint(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            
            Capsule()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle (Color.textPlaceholder)
        }
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

