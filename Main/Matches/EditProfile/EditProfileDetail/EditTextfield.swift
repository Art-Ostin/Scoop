//
//  TextFieldEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI


enum TextFieldOptions: CaseIterable {
    
    case degree, hometown, name, languages
    
    var title: String {
        switch self {
        case .degree: return "Degree"
        case .hometown: return "Hometown"
        case .name: return "Name"
        case .languages: return "I Speak"
        }
    }

    var key: UserProfile.Field {
        switch self {
        case .degree: return .degree
        case .hometown: return .hometown
        case .name: return .name
        case .languages: return .languages
        }
    }
    
    var keyPath: WritableKeyPath<UserProfile, String> {
        switch self {
        case .degree: return \.degree
        case .hometown: return \.hometown
        case .name: return \.name
        case .languages: return \.languages
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

struct TextFieldGeneric: View {
    
    @Environment(\.flowMode) private var mode
    @Binding var text: String
    @FocusState var isFocused: Bool
    let field: TextFieldOptions
    let onTap: () -> ()
    
    var body: some View {
        VStack(spacing: 72)  {
            SignUpTitle(text: field.title)
            customTextField
            if case .onboarding(_, let advance) = mode {
                NextButton(isEnabled: text.count > 0) {onTap()}
                .padding(.top, 36)
            }
        }
        .padding(.horizontal)
        .onAppear {isFocused = true}
        .frame(maxHeight: .infinity, alignment:.top)
        .padding(.top, 96)
        .padding(.horizontal)
        .background(Color.background)
        .ignoresSafeArea(.keyboard)
        .flowNavigation()
    }
}

extension TextFieldGeneric {
    
    private var customTextField: some View  {
        VStack {
            TextField("Type \(field.title) here", text: $text)
                .frame(maxWidth: .infinity)
                .font(.body(24))
                .font(.body(.medium))
                .focused($isFocused)
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

struct EditTextfield : View {
    
    @Bindable var vm: EditProfileViewModel
    let field: TextFieldOptions
    var selection: Binding<String> {
        Binding(
            get: { vm.draft.height },
            set: { vm.set(.height, \.height, to: $0) }
        )
    }
    
    var body: some View {
        TextFieldGeneric(text: selection, field: field) {}
    }
}

struct onboardingTextField {
    @Bindable var vm: OnboardingViewModel
    let field: TextFieldOptions
    @State var text = ""

    var body: some View {
        TextFieldGeneric(text: $text, field: field) {
            vm.saveOnboardingDraft(_kp: field.draftKeyPath, to: text)
        }
    }
}










