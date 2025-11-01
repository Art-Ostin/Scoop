//
//  NewOnboardingContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct OnboardingContainer: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.flowMode) private var mode
    let vm: OnboardingViewModel
    let storage: StorageManaging
    
    @ViewBuilder
    private var stepView: some View {
            switch vm.onboardingStep {
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
            case 12: OnboardingImages(vm: vm, defaults: vm.defaultManager, storage: storage, auth: vm.authManager)
            default: EmptyView()
            }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                stepView
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("SAVE") { dismiss()}
                                .font(.body(12, .bold))
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .overlay(alignment: .top) {
                        Text("\(vm.onboardingStep)/12")
                            .font(.body(12, .bold))
                            .offset(y: -24)
                    }
            }
        }
    }
}


/*
 .environment(\.flowMode, .onboarding(step: vm.onboardingStep) {print(vm.onboardingStep)})
 @Environment(\.flowMode) private var mode
 */
