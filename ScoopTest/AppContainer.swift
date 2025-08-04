//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//

import SwiftUI

struct AppContainer: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    @State var selection: Int = 0
    @Binding var showLogin: Bool
    
    var body: some View {
        
                
        TabView (selection: $selection) {
            
            Tab("", image: "LetterIcon", value: 0) {
                ZStack{
                    Color.background.ignoresSafeArea()
                    MeetContainer(dep: dependencies)
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                        .toolbarBackground(Color.background, for: .tabBar)
                }
            }
            
            Tab("", image: "LogoIcon", value: 1) {
                ZStack{
                    Color.background.ignoresSafeArea()
                        EventView()
//                    EventTestScreen()
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                }
            }
            Tab("", image: "MessageIcon", value: 2) {
                ZStack {
                    Color.background.ignoresSafeArea()
                    
                    MatchesView(showLogin: $showLogin)
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                        .toolbarBackground(Color.background, for: .tabBar)
                }
            }
        }
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .background(Color.clear)
    }
}

#Preview {
    AppContainer(showLogin: .constant(false))
}
