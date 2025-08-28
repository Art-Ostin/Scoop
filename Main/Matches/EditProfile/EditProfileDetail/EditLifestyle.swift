//
//  VicesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct EditLifestyle: View {
    
    @Bindable var vm: EditProfileViewModel
    @Environment(\.flowMode) private var mode
    
    @State var drinking: String?
    @State var smoking: String?
    @State var marijuana: String?
    @State var drugs: String?
    
    var body: some View {
        
        VStack(spacing: 48) {
            vicesOptions(title: "Drinking", isSelected: $drinking)
            vicesOptions(title: "Smoking", isSelected: $smoking)
            vicesOptions(title: "Marijuana", isSelected: $marijuana)
            vicesOptions(title: "Drugs", isSelected: $drugs)
        }
        .flowNavigation()
        .padding(.horizontal)
        .task {
            guard let u = vm.draftUser else {return}
            drinking = u.drinking
            smoking = u.smoking
            marijuana = u.marijuana
            drugs = u.drugs
        }
        .onChange(of: drinking) {
            vm.set(.drinking, \.drinking, to: drinking ?? "")
            saveIfComplete()
        }
        .onChange(of: smoking) {
            vm.set(.smoking, \.smoking, to: smoking ?? "")
            saveIfComplete()
        }
        .onChange(of: marijuana) {
            vm.set(.marijuana, \.marijuana, to: marijuana ?? "")
            saveIfComplete()
        }
        .onChange(of: drugs) {
            vm.set(.drugs, \.drugs, to: drugs ?? "")
            saveIfComplete()
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
    
    private func saveIfComplete() {
        guard
            let d = drinking,
            let s = smoking,
            let m = marijuana,
            let g = drugs
        else { return }
        
        if case .onboarding(_, let advance) = mode {
            advance()
        }
        vm.saveDraft(_kp: \.drinking, to: d)
        vm.saveDraft(_kp: \.smoking, to: s)
        vm.saveDraft(_kp: \.marijuana, to: m)
        vm.saveDraft(_kp: \.drugs, to: g)
    }
}
