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
        
        let fields: [(String, Binding<String?>, UserProfile.Field)] = [
            ("Drinking", $drinking, .drinking),
            ("Smoking", $smoking, .smoking),
            ("Marijuana", $marijuana, .marijuana),
            ("Drugs", $drugs, .drugs)
        ]
        
        VStack(spacing: 48) {
            ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                vicesOptions(title: field.0, isSelected: field.1)
            }
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
        
        .onChange(of: (drinking, smoking, marijuana, drugs)) { old, new in
            
            guard
                 let d = new.0, let s = new.1,
                 let m = new.2, let g = new.3
             else { return }
   
            
            if case .onboarding(_, let advance) = mode {
                advance()
                vm.saveDraft(_kp: \.drinking, to: d)
                vm.saveDraft(_kp: \.smoking, to: s)
                vm.saveDraft(_kp: \.marijuana, to: m)
                vm.saveDraft(_kp: \.drugs, to: g)
            }
        }
        .onChange(of: drinking) { vm.set(.drinking, \.drinking, to: drinking ?? "")}
        .onChange(of: smoking) { vm.set(.smoking, \.smoking, to: smoking ?? "")}
        .onChange(of: marijuana) { vm.set(.marijuana, \.marijuana, to: marijuana ?? "")}
        .onChange(of: drugs) { vm.set(.drugs, \.drugs, to: drugs ?? "")}
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















//#Preview {
//    EditLifestyle()
//}



//if [ self.drinking,
//     self.smoking,
//     self.marijuana,
//     self.drugs ].allSatisfy({ $0 == nil }) {
//    if case .onboarding(_, let advance) = mode {
//        advance()
//        vm.saveDraft(_kp: \.drinking, to: self.drinking)
//        
//        
//    }
