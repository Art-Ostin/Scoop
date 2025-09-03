//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.

import SwiftUI

struct AppContainer: View {
    
    @State var selection: Int = 0
    @Environment(\.appDependencies) private var dep

    
    var body: some View {

        TabView (selection: $selection) {
            
            Tab("", image: "LetterIcon", value: 0) {
                ZStack{
                    MeetView(vm: MeetViewModel(cycleManager: dep.cycleManager, s: dep.sessionManager, cacheManager: dep.cacheManager, eventManager: dep.eventManager, userManager: dep.userManager))
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                        .toolbarBackground(Color.background, for: .tabBar)
                }
            }
            
            Tab("", image: "LogoIcon", value: 1) {
                ZStack{
                    Color.background.ignoresSafeArea()
                    EventContainer(vm: EventViewModel(cacheManager: dep.cacheManager, userManager: dep.userManager, eventManager: dep.eventManager, cycleManager: dep.cycleManager, sessionManager: dep.sessionManager))
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                }
            }
            
            Tab("", image: "MessageIcon", value: 2) {
                ZStack {
                    Color.background.ignoresSafeArea()
                    MatchesView(vm: MatchesViewModel(userManager: dep.userManager, cacheManager: dep.cacheManager, authManager: dep.authManager, storageManager: dep.storageManager, s: dep.sessionManager, eventManager: dep.eventManager, cycleManager: dep.cycleManager, defaultsManager: dep.defaultsManager))
                        .id(dep.sessionManager.user.id)
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                        .toolbarBackground(Color.background, for: .tabBar)
                }
            }
        }
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .background(Color.clear)
        .environment(\.tabSelection, $selection)
    }
}

#Preview {
    AppContainer()
}
