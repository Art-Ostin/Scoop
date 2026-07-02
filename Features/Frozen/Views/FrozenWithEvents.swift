//
//  FrozenScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

import SwiftUI

struct FrozenWithEvents: View {
    @Environment(AppRouter.self) private var router
    
    let vm: FrozenViewModel
    
    @State var tabSelection: AppTab = .events
    @State var topRightOfTitle: CGPoint = .zero
    @State var showFrozenInfo: Bool = false
    
    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $tabSelection) {
                eventsView
                    .coordinateSpace(name: "EventsSpace")
                    .tag(AppTab.events)
                    .tabItem {
                        Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                    }
                    .customAlert(isPresented: $showFrozenInfo, title: "Frozen account", message: "Although your account is frozen, you can still view your upcoming events.", showTwoButtons: false) {showFrozenInfo = false}

                frozenView
                    .tag(AppTab.pastEvents)
                    .tabItem {
                        Label("", image: tabSelection == .pastEvents ? "Snowflake" : "SnowflakeGray")
                    }
            } }  else {
                CustomTabBarContainerView(selection: $tabSelection, tabs: [.events, .pastEvents]) { tab in
                    switch tab {
                    case .events:     eventsView
                    case .pastEvents: frozenView
                    default:          EmptyView()
                    }
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

