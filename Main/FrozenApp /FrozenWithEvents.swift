//
//  FrozenScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

import SwiftUI

struct FrozenWithEvents: View {
    
    let vm: FrozenViewModel
    
    @State var tabSelection: TabBarItem = .events
    @State var topRightOfTitle: CGPoint = .zero

    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $tabSelection) {
                eventsView
                    .tag(TabBarItem.events)
                    .tabItem {
                        Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                    }
                    .overlay {
                        Image(systemName: "info.circle")
                            .frame(width: 20, height: 20)
                            
                    }
                    .onPreferenceChange(TopRightOfTitle.self) { topRightOfTitle in
                        self.topRightOfTitle = topRightOfTitle ?? .zero
                    }
                
                
                frozenView
                    .tag(TabBarItem.matches)
                    .tabItem {
                        Label("", image: tabSelection == .matches ? "Snowflake" : "SnowflakeGray")
                    }
            } }  else {
                CustomTabBarContainerView(selection: $tabSelection) {
                    eventsView.tabBarItem(.events, selection: $tabSelection)
                    frozenView.tabBarItem(.matches, selection: $tabSelection)
                }
            }
    }
}

extension FrozenWithEvents {
    
    private var eventsView: some View {
        EventContainer(vm: EventViewModel(
            cacheManager: vm.cacheManager,
            eventManager: vm.eventManager,
            sessionManager: vm.sessionManager
        ))
    }
    
    private var frozenView: some View {
            FrozenView(vm: vm)
    }
}
