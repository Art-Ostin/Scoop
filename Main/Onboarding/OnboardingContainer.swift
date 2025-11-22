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
                        
                        ToolbarItem(placement: .topBarLeading){
                            Text("\(vm.onboardingStep)/\(12)")
                                .padding(.leading, 4)
                                .frame(width: 100, alignment: .leading)
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
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
}








//extension OnboardingContainer {
//
//    @ViewBuilder
//    func disableGlassEffect() -> some View {
//        if #available(iOS 26.0, *) {
//            self.glassEffect(isEnabled: false)
//        } else {
//            self
//        }
//    }
//}

/*
 //                    .overlay(alignment: .topLeading) {
 //                        Text("\(vm.onboardingStep)/12")
 //                            .font(.body(12, .bold))
 //                    }
 //                    .onChange(of: showOnboarding) { oldValue, newValue in
 //                        dismiss()
 //                    }

 .offset(y: stageOffset(stage: vm.onboardingStep))

func stageOffset(stage: Int) -> CGFloat {
 switch vm.onboardingStep {
 case 0: return -144
 case 1: return -168
 case 2: return -168
 case 3: return -204
 case 4: return -168
 case 5: return  -324
 case 6: return -372
 case 7: return -396
 case 8: return -144
 case 9: return -144
 case 10: return -144
 case 11: return -144
 case 12: return -288
 default: return 48
}
 */
