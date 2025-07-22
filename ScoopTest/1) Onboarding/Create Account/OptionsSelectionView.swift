//
//  OptionsSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/06/2025.
//

import SwiftUI

struct OptionsSelectionView: View {
    
    @Binding var vm: OnboardingViewModel
    
    
    var body: some View {
        
        ZStack {
            VStack(alignment: .leading, spacing: 48) {
                
                Group {
                    switch vm.screen {
                    case 0: SignUpTitle(text: "Sex", count: 6)
                    case 1: SignUpTitle(text: "Attracted To", count: 5)
                    case 2: SignUpTitle(text: "Looking For", count: 4)
                    case 3: SignUpTitle(text: "Year", count: 3)
                    case 4: SignUpTitle(text: "Height", count: 2)
                    default: EmptyView()
                    }
                }
                .animation(nil, value: vm.screen)
                .transition(.identity)
                
                Group {
                    switch vm.screen {
                    case 0: EditSex(isOnboarding: true, screenTracker: $vm)
                    case 1: EditAttractedTo(isOnboarding: true, screenTracker: $vm)
                    case 2: EditLookingFor(isOnboarding: true, screenTracker: $vm)
                    case 3: EditYear(isOnboarding: true, screenTracker: $vm)
                    case 4: EditHeight(isOnboarding: true)
                    default: EmptyView()
                    }
                }
                .frame(height: 216)
                .padding(.horizontal)
                .transition(vm.transition)
            }
            .overlay {
                if vm.screen == 4 {
                    NextButton(isEnabled: true, onTap: {
                        
                        vm.screen += 1
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(y: 24)
                    .padding(.horizontal)
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, vm.screen == 5 ? 168 : 192)
            .padding(.horizontal)
        }
    }
}

//#Preview {
//    OptionsSelectionView(vm: .constant(.init()))
//}
