//
//  TextFieldEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct TextFieldField {
    let title: String
    let keyPath: KeyPath<UserProfile, String?>
    let update: (String) async -> Void
}

struct TextFieldEdit: View {
    
    let field: TextFieldField
    @State private var text: String = ""
    @Environment(\.appDependencies) private var dep
    @Environment(\.flowMode) private var mode
    @FocusState var focused: Bool
    
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
                    NextButton(isEnabled: text.count > 0) {
                        Task { await field.update(text)}
                        advance()
                    }
                }
            }
        }
        .task {
            text = dep.userStore.user?[keyPath: field.keyPath] ?? ""
            focused = true
        }
        .flowNavigation()
        .onChange(of: text) {newValue, _ in
            guard case .profile = mode else { return }
            Task { await field.update(newValue) }
        }
    }
}

//#Preview {
//    TextFieldEdit()
//}
