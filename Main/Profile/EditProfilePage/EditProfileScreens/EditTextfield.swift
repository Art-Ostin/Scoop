//
//  TextFieldEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct OnboardingTextField: View  {
    @Bindable var vm: OnboardingViewModel
    let field: TextFieldOptions
    @State var text = ""

    var body: some View {
        TextFieldGeneric(text: $text, field: field.title)
            .nextButton(isEnabled: text.count > 2, padding: 36) {
                vm.saveAndNextStep(kp: field.draftKeyPath, to: text)
            }
    }
}

struct EditTextfield : View {
    @Bindable var vm: EditProfileViewModel
    let field: TextFieldOptions
    var selection: Binding<String> {
        Binding {vm.draft[keyPath: field.keyPath]} set: {vm.set(field.key, field.keyPath, to: $0)}
    }
    var body: some View {
        TextFieldGeneric(text: selection, field: field.title)
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
        .background(Color.background)
        .ignoresSafeArea(.keyboard)
    }
}



extension TextFieldGeneric {
    
     var customTextField: some View  {
        VStack {
            TextField("Type \(field) here", text: $text)
                .frame(maxWidth: .infinity)
                .font(.body(24))
                .font(.body(.medium))
                .focused($isFocused)
                .autocorrectionDisabled(true)
                .tint(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            
            RoundedRectangle(cornerRadius: 20, style: .circular)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle (Color.grayPlaceholder)
        }
    }
}


enum TextFieldOptions: CaseIterable {
    
    case degree, hometown, name
    
    var title: String {
        switch self {
        case .degree: return "Degree"
        case .hometown: return "Hometown"
        case .name: return "Name"
        }
    }

    var key: UserProfile.Field {
        switch self {
        case .degree: return .degree
        case .hometown: return .hometown
        case .name: return .name
        }
    }
    
    var keyPath: WritableKeyPath<UserProfile, String> {
        switch self {
        case .degree: return \.degree
        case .hometown: return \.hometown
        case .name: return \.name
        }
    }
    
    var draftKeyPath: WritableKeyPath<DraftProfile, String> {
        switch self {
        case .degree: return \.degree
        case .hometown: return \.hometown
        default : return \.degree
        }
    }
}


/*
 .toolbar {
     ToolbarItemGroup(placement: .keyboard) {
         Spacer()
         Button("Done") { isFocused = false }
             .font(.body(.medium))
             .foregroundStyle(Color.accent)
     }
 }
 */
