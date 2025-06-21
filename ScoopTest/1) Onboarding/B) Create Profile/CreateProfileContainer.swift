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
    
    
    
//    @State private var lookingFor: [String] = ["🌳 Something Serious", "🌀 Undecided", "🍹 Something Casual"]
//    
    
    var body: some View {
        
        ZStack {
            
            switch screen {
                
            case 0:
                GoingOutView()
                
            case 1:
                LookingForView()
                
            case 2:
                PassionsView()
                
            case 3:
                PromptView1()
                
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
