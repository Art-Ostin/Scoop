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
        MeetContainer(vm: MeetViewModel(
            cycleManager: dep.cycleManager,
            s: dep.sessionManager,
            imageLoader: dep.imageLoader,
            eventRepo: dep.eventRepo,
            userRepo: dep.userRepo
        ))
    }
    
    private var eventsView: some View {
        EventContainer(vm: EventViewModel(
            imageLoader: dep.imageLoader,
            eventRepo: dep.eventRepo,
            sessionManager: dep.sessionManager
        ))
    }
    
    private var matchesView: some View {
        MatchesView(vm: MatchesViewModel(
            userRepo: dep.userRepo,
            imageLoader: dep.imageLoader,
            authManager: dep.authManager,
            storageManager: dep.storageManager,
            s: dep.sessionManager,
            eventRepo: dep.eventRepo,
            cycleManager: dep.cycleManager,
            defaultsManager: dep.defaultsManager
        ))
    }
}

#Preview {
    AppContainer()
}
