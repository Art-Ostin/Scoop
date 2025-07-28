//
//  VicesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct EditLifestyle: View {
    
    @Environment(\.appDependencies) private var dep
    @Environment(\.flowMode) private var mode

    @State private var drinking: String?
    @State var smoking: String?
    @State var marijuana: String?
    @State var drugs: String?
    
    var body: some View {
        
        let fields: [(String, Binding<String?>, UserProfile.CodingKeys)] = [
            ("Drinking", $drinking, .drinking),
            ("Smoking", $smoking, .smoking),
            ("Marijuana", $marijuana, .marijuana),
            ("Drugs", $drugs, .drugs)
        ]
        let manager = dep.profileManager
        
        VStack(spacing: 48) {
            ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                vicesOptions(title: field.0, isSelected: field.1)
            }
            
            if case .onboarding(_, let advance) = mode {
                NextButton(isEnabled: fields.allSatisfy { $0.1.wrappedValue != nil }) {
                    advance()
                }
            }
        }
        .padding(.horizontal)
        .flowNavigation()
        .task {
            let user = dep.userStore.user
            drinking = user?.drinking
            smoking = user?.smoking
            marijuana = user?.marijuana
            drugs = user?.drugs
        }
        .onChange(of: drinking) { update(key: .drinking, drinking)}
        .onChange(of: smoking) { update(key: .smoking, smoking)}
        .onChange(of: marijuana) { update(key: .marijuana, marijuana)}
        .onChange(of: drugs) { update(key: .drugs, drugs)}
    }
    
    private func update(key: UserProfile.CodingKeys, _ value: String?) {
        Task {
            try? await dep.profileManager.update(values: [key: value ?? ""])
        }
    }

    private func vicesOptions(title: String, isSelected: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.title(28))
            HStack {
                OptionPill(title: "Yes", width: 75, isSelected: isSelected, onTap: {})
                Spacer()
                OptionPill(title: "No", width: 75, isSelected: isSelected, onTap: {})
                Spacer()
                OptionPill(title: "Occasionally", isSelected: isSelected, onTap: {})
            }
        }
    }
}

#Preview {
    EditLifestyle()
}
