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
            s: dep.sessionManager, defaults: dep.defaultsManager,
            userRepo: dep.userRepo,
            profileRepo: dep.profilesRepo,
            eventRepo: dep.eventRepo,
            imageLoader: dep.imageLoader
        ))
    }
    
    private var eventsView: some View {
        EventContainer(vm: EventViewModel(sessionManager: dep.sessionManager, userRepo: dep.userRepo, defaults: dep.defaultsManager, eventRepo: dep.eventRepo, imageLoader: dep.imageLoader))
    }
    
    private var matchesView: some View {
        MatchesView(vm: MatchesViewModel(s: dep.sessionManager, storageService: dep.storageService, defaults: dep.defaultsManager, authService: dep.authService, userRepo: dep.userRepo, profilesRepo: dep.profilesRepo, eventsRepo: dep.eventRepo, imageLoader: dep.imageLoader)
        )
    }
}

#Preview {
    AppContainer()
}
