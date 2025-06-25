//
//  CreateProfileContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/06/2025.
//

import SwiftUI

struct CreateProfileContainer: View {
    
    @Environment(AppState.self) private var appState
    
    private var screen: Int {
        if case .profileSetup(let index) = appState.stage {
            return index
        }
        return 0
    }
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .leading))
    
    
//    @State private var lookingFor: [String] = ["🌳 Something Serious", "🌀 Undecided", "🍹 Something Casual"]
//    
    
    var body: some View {
        
        ZStack {
            
            switch screen {
                
            case 0:
                GoingOutView()
                    .transition(transition)
                
            case 1:
                LookingForView()
                    .transition(transition)

            case 2:
                PassionsView()
                    .transition(transition)
                
            case 3:
                PromptView1()
                    .transition(transition)
                
            case 4:
                PromptView2()
                    .transition(transition)
                
            case 5:
                AddImageView()
                    .transition(transition)
                
            default:
                EmptyView()
            }
            
            XButton(isSave: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.bottom, 12)
            
        }
        .padding(32)
    }
}

#Preview {
    CreateProfileContainer()
        .offWhite()
        .environment(AppState())

}
