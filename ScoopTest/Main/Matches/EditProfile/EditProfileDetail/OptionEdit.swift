//
//  SingleChoiceEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/07/2025.

import SwiftUI

enum OptionField: CaseIterable {
    
    case sex, attractedTo, lookingFor, year
    
    var title: String {
        switch self {
        case .sex: return "Sex"
        case .attractedTo: return "Attracted To"
        case .lookingFor: return "Looking For"
        case .year: return "Year"
        }
    }
    
    var options: [String] {
        switch self {
        case .sex: return ["Man", "Women", "Beyond Binary"]
        case .attractedTo: return ["Men", "Women", "Men & Women", "All Genders"]
        case .lookingFor: return ["Short-term", "Long-term", "Undecided"]
        case .year: return ["U0", "U1", "U2", "U3", "U4"]
        }
    }
    
    var key: UserProfile.CodingKeys {
        switch self {
        case .sex: return .sex
        case .attractedTo: return .attractedTo
        case .lookingFor: return .lookingFor
        case .year: return .year
        }
    }
    
    var keyPath: KeyPath<UserProfile, String?> {
        switch self {
        case .sex: return \.sex
        case .attractedTo: return \.attractedTo
        case .lookingFor: return \.lookingFor
        case .year: return \.year
        }
    }
}

struct OptionEditView: View  {
    @Environment(\.flowMode) private var mode
    
    @Bindable var vm: EditProfileViewModel
    @State private var selection: String? = nil

    let field: OptionField
    let grid = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack {
            Text(field.title)
                .font(.title(32))
            LazyVGrid(columns: grid, spacing: 24) {
                ForEach(field.options, id: \.self) { option in
                    OptionPill(title: option, isSelected: $selection) {
                        select(option)
                    }
                }
            }
        }
        .flowNavigation()
        .onAppear {selection = vm.fetchUserField(field.keyPath)}
    }
    private func select(_ value: String) {
        switch mode {
        case .onboarding(_, let advance):
            advance()
        case .profile: break
        }
        Task { try await vm.updateUser(values: [field.key: value]) }
    }
}
