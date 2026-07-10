//
//  SingleChoiceEdit.swift
//  Scoop
//
//  Created by Art Ostin on 27/07/2025.

import SwiftUI

struct OnboardingOption: View {
    //Injected
    @Bindable var vm: OnboardingViewModel
    let field: OptionField

    //Local view state
    @State private var selection: String?

    var body: some View {
        OptionGeneric(selection: $selection, field: field) {
            vm.saveAndNextStep(kp: field.keyPathDraft, to: $0)
        }
        .frame(maxHeight: .infinity)
        .background(Color.appCanvas)
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

    //Injected
    @Binding var selection: String?
    let field: OptionField
    let onTap: (String) -> ()

    //Local view state
    private let grid = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 84) {
            Text(field.title)
                .font(.title(32))
                .padding(.horizontal, 24)
            LazyVGrid(columns: grid, spacing: Spacing.xxl) {
                ForEach(field.options, id: \.self) { option in
                    OptionPill(title: option, isSelected: $selection) {
                        onTap(option)
                    }
                }
            }
        }
        .padding(.bottom, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCanvas)
    }
}

enum OptionField: CaseIterable {
    
    case sex, attractedTo, lookingFor, year
    
    var title: String {
        switch self {
        case .sex: "Sex"
        case .attractedTo: "Attracted To"
        case .lookingFor: "Looking For"
        case .year: "Year"
        }
    }
    
    var options: [String] {
        switch self {
        case .sex: ["Female", "Male", "Enter your Sex"]
        case .attractedTo: ["Men", "Women", "Men & Women", "All Genders"]
        case .lookingFor: ["Short-term", "Long-term", "Undecided"]
        case .year: ["U0", "U1", "U2", "U3", "U4"]
        }
    }
    
    var key: UserProfile.Field {
        switch self {
        case .sex: .sex
        case .attractedTo: .attractedTo
        case .lookingFor: .lookingFor
        case .year: .year
        }
    }
    
    var keyPath: WritableKeyPath<UserProfile, String> {
        switch self {
        case .sex: \.sex
        case .attractedTo: \.attractedTo
        case .lookingFor: \.lookingFor
        case .year: \.year
        }
    }
    
    var keyPathDraft: WritableKeyPath<DraftProfile, String> {
        switch self {
        case .sex: \.sex
        case .attractedTo: \.attractedTo
        case .lookingFor: \.lookingFor
        case .year: \.year
        }
    }
}
