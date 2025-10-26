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

struct TextFieldEdit: View {
    @Environment(\.flowMode) private var mode
    @Bindable var vm: EditProfileViewModel
    @State private var text: String = ""
    @FocusState var focused: Bool
    let field: TextFieldOptions
    
    var body: some View {
        VStack(spacing: 72)  {
            SignUpTitle(text: field.title)
            customTextField
            if case .onboarding(_, let advance) = mode {
                NextButton(isEnabled: text.count > 0) {
                    advance()
                    vm.saveDraft(_kp: field.draftKeyPath, to: text)
                }
                .padding(.top, 36)
            }
        }
        .padding(.horizontal)
        .onAppear {focused = true}
        .frame(maxHeight: .infinity, alignment:.top)
        .padding(.top, 96)
        .padding(.horizontal)
        .background(Color.background)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if let user = vm.draftUser {
                text = user[keyPath: field.keyPath]
            }
        }
        .flowNavigation()
        .onChange(of: text) { vm.set(field.key, field.keyPath, to: text) }
    }
}

extension TextFieldEdit {

    private var customTextField: some View  {
        VStack {
            TextField("Type \(field.title) here", text: $text)
                .frame(maxWidth: .infinity)
                .font(.body(24))
                .font(.body(.medium))
                .focused($focused)
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
