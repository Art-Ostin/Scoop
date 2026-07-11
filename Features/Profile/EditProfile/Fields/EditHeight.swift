//
//  OptionSelectionView.swift
//  Scoop
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct OnboardingHeight: View {
    //Injected
    @Bindable var vm: OnboardingViewModel

    //Local view state
    @State private var height = "5' 8"

    var body: some View {
        HeightGeneric(selection: $height)
            .nextButton(isValid: true) {
                vm.saveAndNextStep(kp: \.height, to: height)
            }
            .onAppear {
                if let draft = vm.draftProfile {
                    if !draft.height.isEmpty  {
                        height = draft.height
                    }
                }
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
        HeightGeneric(selection: selection)
    }
}

struct HeightGeneric: View {
    @Binding var selection: String
    let heightOptions = (45...84).map {"\($0 / 12)' \($0 % 12)"}
    
    var body: some View {
        VStack(spacing: Spacing.titleGap) {
            SignUpTitle(text: "Height")
            Picker("Height", selection: $selection) {
                ForEach(heightOptions, id: \.self) { option in
                    Text(option).font(.body(20))
                }
            }
            .pickerStyle(.wheel)
            .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 144) //Geometry: drops the wheel to sit under the pushed-down title
        .padding(.horizontal, Spacing.margin)
        .background(Color.appCanvas)
    }
}
