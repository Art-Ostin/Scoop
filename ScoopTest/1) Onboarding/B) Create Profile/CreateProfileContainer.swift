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
    
    
//    @State private var goingOut: [String] = ["🌞 Everyday", "🍻5/6 a week", "🎟 3/4 a week", "🎶 twice a week", "🎊 Once a week", "🌙 Sometimes", "📝Rarely"]
//    @State private var lookingFor: [String] = ["🌳 Something Serious", "🌀 Undecided", "🍹 Something Casual"]
//    
    
    var body: some View {
        
        switch screen {
            
        case 0:
            GoingOutView ()
            
            
            
        case 2:
            PassionsView()
            
            
            
            
            
            
        default:
            EmptyView()
            
        }
    }
}

#Preview {
    CreateProfileContainer()
        .offWhite()
        .environment(AppState())

}
