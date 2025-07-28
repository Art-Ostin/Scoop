//
//  OnboardingContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

//struct OnboardingContainer: View {
//    
//    
//    @Environment(\.appDependencies) private var dependencies: AppDependencies
//    
//    @Binding var vm: OnboardingViewModel
//    
//    
//    
//    @Binding var showLogin: Bool
//    
//    var body: some View {
//        
//        
//        NavigationStack {
//            
//            //Need the ZStack for the transitions
//
////            ZStack {
////                Group {
////                    switch vm.screen {
////                    case 0...4: OptionsSelectionView(vm: $vm)
////                    case 5: EditLifestyle()
////                    case 6: EditInterests()
////                    case 7: EditNationality()
////                    case 8: EditTextFieldLayout(isOnboarding: true, title: "Degree", screenTracker: $vm)
////                    case 9: EditTextFieldLayout(isOnboarding: true, title: "Hometown", screenTracker: $vm)
////                    case 10: EditPrompt(prompts: Prompts.instance.prompts1, promptIndex: 1)
////                    case 11: EditPrompt(prompts: Prompts.instance.prompts2, promptIndex: 2)
////                    case 12: AddImageView(dependencies: dependencies, showLogin: $showLogin)
////                    default: EmptyView()
////                }
//                }
//                .transition(vm.transition)
//
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(Color.background)
//            .task {
//                try? await dependencies.userStore.loadUser()
//            }
//        }
//    }
//}
//        
        

