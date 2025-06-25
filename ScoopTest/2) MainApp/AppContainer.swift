//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//

import SwiftUI

struct AppContainer: View {
    @State var selection: Int = 0
    
    var body: some View {
        
        TabView (selection: $selection) {
            Tab("", image: "LetterIcon", value: 0) {
                ZStack{
                    Color.background.ignoresSafeArea()
                    MeetContainer()
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                        .toolbarBackground(Color.background, for: .tabBar)
                }
            }
            
            Tab("", image: "LogoIcon", value: 1) {
                ZStack{
                    Color.background.ignoresSafeArea()
                    createProfilePage(title: "Events", Screenimage: "Monkey", description: "If you match with someone and are meeting up, details will appear here.", showProfile: false)
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                        .toolbarBackground(Color.background, for: .tabBar)
                }
            }
            
            Tab("", image: "MessageIcon", value: 2) {
                ZStack {
                    Color.background.ignoresSafeArea()
                    createProfilePage(title: "Matches", Screenimage: "DancingCats", description: "You can see all previous meet ups here", showProfile: true)
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
    AppContainer()
        .environment(AppState())
}
