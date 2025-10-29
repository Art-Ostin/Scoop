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
    
    var key: UserProfile.Field {
        switch self {
        case .sex: return .sex
        case .attractedTo: return .attractedTo
        case .lookingFor: return .lookingFor
        case .year: return .year
        }
    }
    
    var keyPath: WritableKeyPath<UserProfile, String> {
        switch self {
        case .sex: return \.sex
        case .attractedTo: return \.attractedTo
        case .lookingFor: return \.lookingFor
        case .year: return \.year
        }
    }
    
    var keyPathDraft: WritableKeyPath<DraftProfile, String> {
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

    let field: OptionField
    let grid = [GridItem(.flexible()), GridItem(.flexible())]
    
    //If onboarding don't mutate draftProfile, just submit whatever user inputs
    var selection: Binding<String?> {
        switch mode {
        case .onboarding:
            return Binding(get: { nil }, set: { _ in })
        case .profile:
            return Binding(
                get: { vm.draft[keyPath: field.keyPath] },
                set: { vm.set(field.key, field.keyPath, to: $0 ?? "") }
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            Text(field.title)
                .font(.title(32))
                .padding(.horizontal, 24)
            LazyVGrid(columns: grid, spacing: 24) {
                ForEach(field.options, id: \.self) { option in
                    OptionPill(title: option, isSelected: selection) {
                        select(option)
                    }
                }
            }
        }
        .flowNavigation()
    }
    
    private func select(_ value: String) {
        switch mode {
        case .onboarding(_, let advance):
            vm.saveDraft(_kp: field.keyPathDraft, to: value)
            advance()
        case .profile:
            selection.wrappedValue = value           
        }
    }
}
