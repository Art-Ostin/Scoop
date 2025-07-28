//
//  SingleChoiceEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/07/2025.
//

import SwiftUI

struct OptionField {
    let title: String
    let options: [String]
    let keyPath: KeyPath<UserProfile, String?>
    let update: (String) async -> Void
}

struct OptionEditView: View  {
    
    let field: OptionField
    @State private var selection: String? = nil
    @Environment(\.appDependencies) private var deps
    @Environment(\.flowMode) private var mode

    var body: some View {
        
        let grid = [GridItem(.flexible()), GridItem(.flexible())]
        
        VStack {
            LazyVGrid(columns: grid, spacing: 24) {
                ForEach(field.options, id: \.self) { option in
                    OptionPill(title: option, isSelected: $selection) {
                        select(option)
                    }
                }
            }
        }
        .task {selection == deps.userStore.user?[keyPath: field.keyPath] }
    }
    
    private func select(_ value: String) {
        Task { await field.update(value) }
        switch mode {
        case .onboarding(_, let advance):
            advance()
        case .profile: break
        }
    }
}

#Preview {

    
    
}
