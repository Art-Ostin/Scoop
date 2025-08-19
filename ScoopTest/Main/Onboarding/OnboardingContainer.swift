//
//  NewOnboardingContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct OnboardingContainer: View {
    @Environment(\.appDependencies) private var dep
    @Environment(\.flowMode) private var mode
    @State var vm: EditProfileViewModel
    @Binding var current: Int
    
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Group {
                    switch current {
                    case 0: OptionEditView(vm: $vm, field: .sex)
                    case 1: OptionEditView(vm: $vm, field: .attractedTo)
                    case 2: OptionEditView(vm: $vm, field: .lookingFor)
                    case 3: OptionEditView(vm: $vm, field: .year)
                    case 4: EditHeight(vm: $vm)
                    case 5: EditLifestyle()
                    case 6: EditInterests(vm: $vm)
                    case 7: EditNationality(vm: $vm)
                    case 8: TextFieldEdit(vm: $vm, field: .hometown)
                    case 9: TextFieldEdit(vm: $vm, field: .degree)
                    default: EmptyView()
                    }
                }
                .environment(\.flowMode, .onboarding(step: current) {
                    withAnimation { current += 1 }
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
}
