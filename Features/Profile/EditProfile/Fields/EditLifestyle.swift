//
//  VicesView.swift
//  Scoop
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct OnboardingLifestyle: View {
    
    @Bindable var vm: OnboardingViewModel
    
    @State private var drinking: String?
    @State private var smoking: String?
    @State private var marijuana: String?
    @State private var drugs: String?
    
    var body: some View {
        GenericLifestyle(drinking: $drinking, smoking: $smoking, marijuana: $marijuana, drugs: $drugs)
            .onChange(of: drinking) {saveIfComplete()}
            .onChange(of: smoking) { saveIfComplete()}
            .onChange(of: marijuana) {saveIfComplete()}
            .onChange(of: drugs) {saveIfComplete()}
            .frame(maxHeight: .infinity)
            .background(Color.appCanvas)
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

        VStack(spacing: Spacing.xxl) {
            vicesOptions(title: "Drinking", selection: $drinking)
            vicesOptions(title: "Smoking", selection: $smoking)
            vicesOptions(title: "Marijuana", selection: $marijuana)
            vicesOptions(title: "Drugs", selection: $drugs)
        }
        .padding(.horizontal)
        .padding(.bottom, Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCanvas)
    }
    
    private func vicesOptions(title: String, selection: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(title)
                .font(.title(28))
            HStack {
                vicePill("Yes", width: 75, selection: selection)
                Spacer()
                vicePill("No", width: 75, selection: selection)
                Spacer()
                vicePill("Occasionally", selection: selection)
            }
        }
    }

    private func vicePill(_ option: String, width: CGFloat = 148, selection: Binding<String?>) -> some View {
        OptionPill(title: option, width: width, isSelected: selection.wrappedValue == option) {
            selection.wrappedValue = option
        }
    }
}
