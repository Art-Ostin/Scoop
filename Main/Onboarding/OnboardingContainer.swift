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

    @ViewBuilder
    private var stepView: some View {
        switch defaults.onboardingStep {
        case 0: OnboardingOption(vm: vm, field: .sex)
        case 1: OnboardingOption(vm: vm, field: .attractedTo)
        case 2: OnboardingOption(vm: vm, field: .lookingFor)
        case 3: OnboardingOption(vm: vm, field: .year)
        case 4: OnboardingHeight(vm: vm)
        case 5: OnboardingLifestyle(vm: vm)
        case 6: OnboardingInterests(vm: vm)
        case 7: OnboardingNationality(vm: vm)
        case 8: OnboardingTextField(vm: vm, field: .hometown)
        case 9: OnboardingTextField(vm: vm, field: .degree)
        case 10: OnboardingPrompt(vm: vm, promptIndex: 0)
        case 11: OnboardingPrompt(vm: vm, promptIndex: 1)
        case 12: AddImageView(vm: vm)
        default: EmptyView()
        }
    }
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                stepView
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
