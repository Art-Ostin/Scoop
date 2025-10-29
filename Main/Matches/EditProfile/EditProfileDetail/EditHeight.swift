//
//  OptionSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct EditHeight: View {
    
    @Bindable var vm: EditProfileViewModel
    @Environment(\.flowMode) private var mode
    
    let heightOptions = (45...84).map { inches in
        "\(inches / 12)' \(inches % 12)"
    }
    @State private var localHeight = ""
    var selection: Binding<String> {
        switch mode {
        case .onboarding:
            return $localHeight
        case .profile:
            return Binding(
                get: { vm.draft.height },
                set: { vm.set(.height, \.height, to: $0) }
            )
        }
    }
    
    
    var body: some View {
        VStack {
            SignUpTitle(text: "Height")
            Picker("Height", selection: selection) {
                ForEach(heightOptions, id: \.self) { option in
                    Text(option).font(.body(20))
                }
            }
            .pickerStyle(.wheel)
            .padding(.horizontal, 36)
            if case .onboarding(_, let advance) = mode {
                NextButton(isEnabled: true) {
                    vm.saveDraft(_kp: \.height, to: selection.wrappedValue)
                    advance()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .background(Color.background)
        .flowNavigation()
    }
}

