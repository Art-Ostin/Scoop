//
//  NewOnboardingContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct OnboardingContainer: View {
    @Environment(\.flowMode) private var mode
    @State var vm: OnboardingViewModel
    
    @Bindable var defaults: DefaultsManager
    @Binding var current: Int
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Group {
                    switch defaults.onboardingStep {
                    case 0: OnboardingEdit(vm: vm, field: .sex)
                    case 1: OnboardingEdit(vm: vm, field: .attractedTo)
                    case 2: OnboardingEdit(vm: vm, field: .lookingFor)
                    case 3: OnboardingEdit(vm: vm, field: .year)
                    case 4: OnboardingHeight(vm: vm)
                    case 5: OnboardingLifestyle(vm: vm)
                    case 6: EditInterests(vm: vm)
                    case 7: EditNationality(vm: vm)
                    case 8: TextFieldEdit(vm: vm, field: .hometown)
                    case 9: TextFieldEdit(vm: vm, field: .degree)
                    case 10: EditPrompt(vm: vm, promptIndex: 0)
                    case 11: EditPrompt(vm: vm, promptIndex: 1)
                    case 12: AddImageView(vm: vm)
                    default: EmptyView()
                    }
                }
                .environment(\.flowMode, .onboarding(step: current) {
                    withAnimation { defaults.advanceOnboarding() }
                    print(String(defaults.onboardingStep))
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                .overlay(alignment: .top) {
                    Text("\(defaults.onboardingStep)/12")
                        .font(.body(12, .bold))
                        .offset(y: -36)
                }
            }
        }
    }
}
