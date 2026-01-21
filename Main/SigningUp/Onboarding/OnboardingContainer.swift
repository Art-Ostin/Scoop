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
    @State private var showSaved: Bool = false
    
    
    
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
            ZStack(alignment: .topLeading) {
                stepView
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body(16, .bold))
                                    .padding(24)
                                    .contentShape(Rectangle())
                                    .padding(-24)
                            }
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            if vm.onboardingStep > 0 {
                                Button {
                                    vm.goBackStep()
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.body(16, .bold))
                                        .frame(width: 30, height: 60) //Frame Solves a bug for quick dismissing
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .principal) {
                            ZStack {
                                Text("\(vm.onboardingStep)/\(12)")
                                    .font(.body(12, .bold))
                                    .foregroundStyle(bounce ? .accent : .accent)
                                    .opacity(showSaved ? 0 : 1)
                                
                                HStack(spacing: 12) {
                                    Text("Saved")
                                        .font(.body(14, .bold))
                                        .foregroundStyle(Color(red: 0.16, green: 0.65, blue: 0.27))
                                    
                                    Image("GreenTick")
                                }
                                .opacity(showSaved ? 1 : 0)
                             }
                            .animation(.easeInOut(duration: 0.25), value: showSaved)
                        }
                        .hideSharedBackgroundIfAvailable()
                    }
                    .transition(vm.transitionStep)
                    .animation(.easeInOut(duration: 0.3), value: showSaved)
                    .onChange(of: vm.onboardingStep) { oldValue, newValue in
                        guard newValue > oldValue else {return}
                        showSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            showSaved = false
                        }
                    }
            }
            .navigationBarTitleDisplayMode(.inline) //Fixes Bug: decreases the top container pushing all the content down
        }
    }
}
