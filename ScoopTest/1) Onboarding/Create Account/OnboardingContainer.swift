//
//  OnboardingContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct OnboardingContainer: View {
    
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @Binding var vm: OnboardingViewModel
    
    
    
    @Binding var showLogin: Bool
    
    var body: some View {
        
        
        NavigationStack {
            
            //Need the ZStack for the transitions

            ZStack {
                Group {
                    switch vm.screen {
                    case 0...4: OptionsSelectionView(vm: $vm)
                    case 5: EditLifestyle()
                    case 6: EditInterests(title: "Interests", isOnboarding: true, screenTracker: $vm)
                    case 7: EditNationality()
                    case 8: EditTextFieldLayout(isOnboarding: true, title: "Degree", screenTracker: $vm)
                    case 9: EditTextFieldLayout(isOnboarding: true, title: "Hometown", screenTracker: $vm)
                    case 10: EditPrompt(promptIndex: 1, prompts: Prompts.instance.prompts1, isOnboarding: true, screenTracker: $vm)
                    case 11: EditPrompt(promptIndex: 2, prompts: Prompts.instance.prompts2, isOnboarding: true, screenTracker: $vm)
                    case 12: AddImageView(dependencies: dependencies, showLogin: $showLogin)
                    default: EmptyView()
                }
                }
                .transition(vm.transition)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
            .task {
                try? await dependencies.userStore.loadUser()
            }
        }
    }
}
        
        

