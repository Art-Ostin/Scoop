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

    @State var drinking: String?
    @State var smoking: String?
    @State var marijuana: String?
    @State var drugs: String?
    
    var body: some View {
        
        let fields: [(String, Binding<String?>, UserProfile.Field)] = [
            ("Drinking", $drinking, .drinking),
            ("Smoking", $smoking, .smoking),
            ("Marijuana", $marijuana, .marijuana),
            ("Drugs", $drugs, .drugs)
        ]
        
        VStack(spacing: 48) {
            ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                vicesOptions(title: field.0, isSelected: field.1)
            }
        }
        .flowNavigation()
        .padding(.horizontal)
        .task {
            let u = dep.sessionManager.user
            drinking = u.drinking
            smoking = u.smoking
            marijuana = u.marijuana
            drugs = u.drugs
//            
//            if [ u.drinking,
//                 u.smoking,
//                 u.marijuana,
//                 u.drugs ].allSatisfy({ $0 == nil }) {
//                if case .onboarding(_, let advance) = mode {
//                    advance()
//                }
//            }
        }
        .onChange(of: drinking) { update(key: .drinking, drinking)}
        .onChange(of: smoking) { update(key: .smoking, smoking)}
        .onChange(of: marijuana) { update(key: .marijuana, marijuana)}
        .onChange(of: drugs) { update(key: .drugs, drugs)}
        
    }
    
    private func update(key: UserProfile.Field, _ value: String?) {
        Task {
            try? await dep.userManager.updateUser(values: [key: value ?? ""])
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
