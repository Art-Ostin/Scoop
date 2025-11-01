//
//  OptionSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct OnboardingHeight: View {
    @State private var height = "5' 8"
    @Bindable var vm: OnboardingViewModel
    
    var body: some View {
        HeightGeneric(selection: $height) {
            vm.saveAndNextStep(kp: \.height, to: height)
        }
    }
}

struct EditHeight: View {
    @Bindable var vm: EditProfileViewModel
    var selection: Binding<String> {
        Binding(
            get: { vm.draft.height },
            set: { vm.set(.height, \.height, to: $0) }
        )
    }
    var body: some View {
        HeightGeneric(selection: selection) {}
    }
}

struct HeightGeneric: View {
    @Environment(\.flowMode) private var mode
    @Binding var selection: String
    let heightOptions = (45...84).map {"\($0 / 12)' \($0 % 12)"}
    let onTap: () -> ()
    
    var body: some View {
        VStack {
            SignUpTitle(text: "Height")
            Picker("Height", selection: $selection) {
                ForEach(heightOptions, id: \.self) { option in
                    Text(option).font(.body(20))
                }
            }
            .pickerStyle(.wheel)
            .padding(.horizontal, 36)
            
            if case .onboarding(_, _) = mode {
                NextButton(isEnabled: true) {onTap()}
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .background(Color.background)
        .flowNavigation()
    }
}
