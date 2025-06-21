//
//  OnboardingContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct OnboardingContainer: View {
    
    @Environment(AppState.self) private var appState
    
    
    private var screen: Int {
        
        if case .onboarding(let index) = appState.stage {
            return index
        }
        return 0
    }
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
    var body: some View {
        
        ZStack {
            
            Group {
                switch screen {
                    
                case 0:
                    AddEmailView()
                        .transition(transition)
                
                case 1...4:
                    OptionsSelectionView()
                        .transition(transition)
                
                case 5:
                    NationalityView()
                        .transition(transition)
                    
                case 6:
                    FacultyView()
                        .transition(transition)
                    
                case 7:
                    HomeTownView()
                        .transition(transition)
                    
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
        .offWhite()
}
