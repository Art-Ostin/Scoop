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
    
    var key: UserProfile.CodingKeys {
        switch self {
        case .degree: return .degree
        case .hometown: return .hometown
        case .name: return .name
        case .languages: return .languages
        }
    }
    
    var keyPath: KeyPath<UserProfile, String?> {
        switch self {
        case .degree: return \.degree
        case .hometown: return \.hometown
        case .name: return \.name
        case .languages: return \.languages
        }
    }
}

struct TextFieldEdit: View {
    @Environment(\.flowMode) private var mode
    @Binding var vm: EditProfileViewModel
    @State private var text: String = ""
    @FocusState var focused: Bool
    let field: TextFieldOptions
    
    var body: some View {
        
        VStack {

            SignUpTitle(text: field.title)
            
            VStack {
                TextField("Type \(field.title) here", text: $text)
                    .frame(maxWidth: .infinity)
                    .font(.body(24))
                    .font(.body(.medium))
                    .focused($focused)
                    .tint(.blue)
                
                RoundedRectangle(cornerRadius: 20, style: .circular)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundStyle (Color.grayPlaceholder)
                
                if case .onboarding(_, let advance) = mode {
                    NextButton(isEnabled: text.count > 0) { advance() }
                }
            }
        }
        .onAppear {
            text =  vm.fetchUserField(field.keyPath) ?? ""
            focused = true
        }
        .flowNavigation()
        .onChange(of: text) { Task { try await vm.updateUser(values: [field.key : text])} }
    }
}
