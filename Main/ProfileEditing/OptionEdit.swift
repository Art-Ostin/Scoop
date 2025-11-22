//
//  SingleChoiceEdit.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/07/2025.

import SwiftUI

struct OnboardingOption: View {
    @Bindable var vm: OnboardingViewModel
    @State var selection: String?
    let field : OptionField
    
    var body: some View {
        OptionGeneric(selection: $selection, field: field) {
            vm.saveAndNextStep(kp: field.keyPathDraft, to: $0)
        }
        .frame(maxHeight: .infinity)
        .background(Color.background)
    }
}

struct EditOption: View {

    @Bindable var vm: EditProfileViewModel
    let field: OptionField
    var selection: Binding<String?> {
        Binding {vm.draft[keyPath: field.keyPath]} set: {vm.set(field.key, field.keyPath, to: $0 ?? "")}
    }
    var body: some View {
        OptionGeneric(selection: selection, field: field) {selection.wrappedValue = $0}
    }
}

struct OptionGeneric: View {

    @Binding var selection: String?
    let field: OptionField
    let grid = [GridItem(.flexible()), GridItem(.flexible())]
    let onTap: (String) -> ()
    
    @State var showCustomSex: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 84) {
            Text(field.title)
                .font(.title(32))
                .padding(.horizontal, 24)
            LazyVGrid(columns: grid, spacing: 48) {
                ForEach(field.options, id: \.self) { option in
                    OptionPill(title: option, isSelected: $selection) {
                        onTap(option)
                    }
                }
            }
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}

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
        case .sex: return ["Female", "Male", "Enter your Sex"]
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
