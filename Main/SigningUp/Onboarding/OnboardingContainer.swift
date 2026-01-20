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
    @State private var enlargenStep: Bool = false
    
    
    @ViewBuilder
    private var stepView: some View {
            switch vm.onboardingStep {
            case 0: OnboardingSex(vm: vm)
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
    @State private var bounce = false
    var body: some View {
        NavigationStack {
            ZStack {
                stepView
                    .toolbar {
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body(16, .bold))
                            }
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            if vm.onboardingStep > 0 {
                                Button {
                                    vm.goBackStep()
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.body(16, .bold))
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .principal) {
                            Text("\(vm.onboardingStep)/\(12)")
                                .font(.body(12, .bold))
                                .foregroundStyle(bounce ? .accent : .accent)
                                .scaleEffect(bounce ? 1.4 : 1.0, anchor: .leading)
                                .rotationEffect(.degrees(bounce ? -4 : 0), anchor: .leading)
                                .animation(
                                    .spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0.25),
                                    value: bounce
                                )
                                .onChange(of: vm.onboardingStep) {
                                    bounce = true
                                    Task {
                                        try? await Task.sleep(nanoseconds: 300_000_000)
                                        bounce = false
                                    }
                                }
                        }
                        .hideSharedBackgroundIfAvailable()
                    }
                    .transition(vm.transitionStep)
            }
        }
    }
}

/*
 //Moving Forward Animation:
 .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

 //Moving Backward Animation:
 .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
 */
