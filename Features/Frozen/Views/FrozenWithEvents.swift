//
//  FrozenScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

import SwiftUI

struct FrozenWithEvents: View {
    //Injected
    @Environment(AppRouter.self) private var router
    let vm: FrozenViewModel

    //Local view state
    @State private var tabSelection: AppTab = .events
    @State private var showFrozenInfo: Bool = false
    
    var body: some View {
        TabView(selection: $tabSelection) {
            eventsView
                .coordinateSpace(name: "EventsSpace")
                .tag(AppTab.events)
                .tabItem {
                    Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                }
                .customAlert(isPresented: $showFrozenInfo, title: "Frozen account", message: "Although your account is frozen, you can still view your upcoming events.", showTwoButtons: false) {showFrozenInfo = false}

            frozenView
                .tag(AppTab.messages)
                .tabItem {
                    Label("", image: tabSelection == .messages ? "Snowflake" : "SnowflakeGray")
                }
        }
    }
}

extension FrozenWithEvents {
    
    private var eventsView: some View {
        @Bindable var router = router
        
        return EventsContainer(
            vm: EventsViewModel(
                session: vm.session,
                userRepo: vm.userRepo,
                defaults: vm.defaults,
                eventRepo: vm.eventRepo,
                chatRepo: vm.chatRepo,
                imageLoader: vm.imageLoader
            ),
            showMessageScreen: $router.showMessageScreen,
            path: $router.eventsPath
        )
    }
    
    private var frozenView: some View {
            FrozenView(vm: vm)
    }
}
