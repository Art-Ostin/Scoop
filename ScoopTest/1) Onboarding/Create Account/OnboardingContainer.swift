//
//  OnboardingContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI





struct OnboardingContainerViewModel {
    
    var screen: Int = 0
    
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
}

struct OnboardingContainer: View {
        
    @State var vm = OnboardingContainerViewModel()
    
    
    var body: some View {
        
        ZStack {
            
            Group {
                switch vm.screen {
                
                case 0...3:
                    OptionsSelectionView()
                        .transition(vm.transition)
                
                case 4:
                    NationalityView()
                        .transition(vm.transition)
                    
                case 5:
                    FacultyView()
                        .transition(vm.transition)
                    
//                case 6:
//                    HomeTownView()
//                        .transition(transition)
                    
                default:
                    EmptyView()
                }
            }
            XButton()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .padding(32)
    }
}

#Preview {
    OnboardingContainer()
        .environment(AppState())
}
