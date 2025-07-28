//
//  TextFieldEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct TextFieldField {
    let title: String
    let keyPath: KeyPath<UserProfile, String>
    let update: (String) async -> Void
}

struct TextFieldEdit: View {
    
    let field: TextFieldField
    @State private var text: String = ""
    @Environment(\.appDependencies) private var dep
    @Environment(\.flowMode) private var flow
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
            }
        }
        .task {
           text = dep.userStore.user? [keyPath: field.keyPath] ?? ""
            focused = true
        }
        .onChange(of: text) {
//           text = dep.userStore.user?[keyPath: field.keyPath]
        }        
        .flowNavigation()

    }
}

//#Preview {
//    TextFieldEdit()
//}
