//
//  BlockedWithEvents.swift
//  Scoop
//
//  Created by Art Ostin on 25/01/2026.
//

import SwiftUI

struct BlockedWithEvents: View {
    
    @State var tabSelection: TabBarItem = .events
    @State var showBlockedInfo: Bool = false
    let vm: FrozenViewModel

    var body: some View {
        if #available(iOS 26.0, *) {
        TabView(selection: $tabSelection) {
            eventsView
                .coordinateSpace(name: "EventsSpace")
                .tag(TabBarItem.events)
                .tabItem {
                    Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                }
                .customAlert(isPresented: $showBlockedInfo, title: "Frozen account", message: "Although your account is blocked, you can still view upcoming events.", showTwoButtons: false) {showBlockedInfo = false}
            blockedView
                .tag(TabBarItem.matches)
                .tabItem {
                    Label("", image: tabSelection == .matches ? "Snowflake" : "SnowflakeGray")
                }
        } }  else {
            CustomTabBarContainerView(selection: $tabSelection) {
                eventsView.tabBarItem(.events, selection: $tabSelection)
                blockedView.tabBarItem(.matches, selection: $tabSelection)
            }
        }
    }
}

extension BlockedWithEvents {
    private var eventsView: some View {
        EventContainer(vm: EventViewModel(
            cacheManager: vm.cacheManager,
            eventManager: vm.eventManager,
            sessionManager: vm.sessionManager
        ), showFrozenInfo: $showBlockedInfo, isFrozenEvent: true)
    }
    
    private var blockedView: some View {
        BlockedScreen(vm: vm, email: vm.user.email)
    }
}
