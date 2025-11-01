//
//  VicesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct OnboardingLifestyle: View {
    
    @Bindable var vm: OnboardingViewModel
    @Environment(\.flowMode) private var mode
    
    @State var drinking: String? = ""
    @State var smoking: String? = ""
    @State var marijuana: String? = ""
    @State var drugs: String? = ""
    
    var body: some View {
        GenericLifestyle(drinking: $drinking, smoking: $smoking, marijuana: $marijuana, drugs: $drugs)
            .onChange(of: drinking) {saveIfComplete()}
            .onChange(of: smoking) { saveIfComplete()}
            .onChange(of: marijuana) {saveIfComplete()}
            .onChange(of: drugs) {saveIfComplete()}
    }
    
    private func saveIfComplete() {
        guard
            let d = drinking,
            let s = smoking,
            let m = marijuana,
            let g = drugs
        else { return }
        vm.saveAndNextStep(kp: \.drinking, to: d, updateOnly: true)
        vm.saveAndNextStep(kp: \.smoking, to: s, updateOnly: true)
        vm.saveAndNextStep(kp: \.marijuana, to: m, updateOnly: true)
        vm.saveAndNextStep(kp: \.drugs, to: g)
    }
}

struct EditLifestyle: View {
    
    @Bindable var vm: EditProfileViewModel
    @Environment(\.flowMode) private var mode
    
    
    var drinking: Binding<String?> {
        Binding(get: { vm.draft.drinking }, set: { newValue in
            vm.set(.drinking, \.drinking, to: newValue ?? "")
        })
    }

    var smoking: Binding<String?> {
        Binding(get: { vm.draft.smoking }, set: { newValue in
            vm.set(.smoking, \.smoking, to: newValue ?? "")
        })
    }
    var marijuana: Binding<String?> {
        Binding(get: { vm.draft.marijuana }, set: { newValue in
            vm.set(.marijuana, \.marijuana, to: newValue ?? "")
        })
    }
    var drugs: Binding<String?> {
        Binding(get: { vm.draft.drugs }, set: { newValue in
            vm.set(.drugs, \.drugs, to: newValue ?? "")
        })
    }
    var body: some View {
        GenericLifestyle(drinking: drinking, smoking: smoking, marijuana: marijuana, drugs: drugs)
    }
}

struct GenericLifestyle: View {
    
    @Binding var drinking: String?
    @Binding var smoking: String?
    @Binding var marijuana: String?
    @Binding var drugs: String?
    
    var body: some View {

        VStack(spacing: 48) {
            vicesOptions(title: "Drinking", isSelected: $drinking)
            vicesOptions(title: "Smoking", isSelected: $smoking)
            vicesOptions(title: "Marijuana", isSelected: $marijuana)
            vicesOptions(title: "Drugs", isSelected: $drugs)
        }
        .flowNavigation()
        .padding(.horizontal)
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
