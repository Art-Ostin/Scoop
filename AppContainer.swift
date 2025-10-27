//
//  ParentContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.

import SwiftUI

struct AppContainer: View {
    
    @State var tabSelection: TabBarItem = .meet
    @Environment(\.appDependencies) private var dep
    
        
    var body: some View {
        
        if #available(iOS 26.0, *) {
            TabView(selection: $tabSelection) {
                meetView
                    .tag(TabBarItem.meet)
                    .tabItem {
                        Label("", image: tabSelection == .meet ? "BlackLogo" : "AppLogoBlack")
                    }
                    .ignoresSafeArea()
                
                eventsView
                    .tag(TabBarItem.events)
                    .tabItem {
                        Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                    }
                matchesView
                    .tag(TabBarItem.matches)
                    .tabItem {
                        Label("", image: tabSelection == .matches ? "BlackMessage" : "MessageIcon")
                    }
            }
            .tint(.black)
        } else {
            CustomTabBarContainerView(selection: $tabSelection) {
                meetView .tabBarItem(.meet, selection: $tabSelection)
                eventsView.tabBarItem(.events, selection: $tabSelection)
                matchesView.tabBarItem(.matches, selection: $tabSelection)
            }
        }
    }
}

extension AppContainer {
    
    private var meetView: some View {
        MeetView(vm: MeetViewModel(
            cycleManager: dep.cycleManager,
            s: dep.sessionManager,
            cacheManager: dep.cacheManager,
            eventManager: dep.eventManager,
            userManager: dep.userManager
        ))
    }
    
    private var eventsView: some View {
        EventContainer(vm: EventViewModel(
            cacheManager: dep.cacheManager,
            userManager: dep.userManager,
            eventManager: dep.eventManager,
            cycleManager: dep.cycleManager,
            sessionManager: dep.sessionManager
        ))
    }
    
    private var matchesView: some View {
        MatchesView(vm: MatchesViewModel(
            userManager: dep.userManager,
            cacheManager: dep.cacheManager,
            authManager: dep.authManager,
            storageManager: dep.storageManager,
            s: dep.sessionManager,
            eventManager: dep.eventManager,
            cycleManager: dep.cycleManager,
            defaultsManager: dep.defaultsManager
        ))
    }
}

#Preview {
    AppContainer()
}
