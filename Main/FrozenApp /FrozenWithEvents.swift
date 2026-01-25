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
    @State var showFrozenInfo: Bool = false

    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $tabSelection) {
                eventsView
                    .tag(TabBarItem.events)
                    .tabItem {
                        Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                    }
                    .overlayPreferenceValue(TitleBoundsKey.self) { anchor in
                        GeometryReader { proxy in
                            if let anchor {
                                let rect = proxy[anchor] // rect in EventsSpace
                                Button {
                                    showFrozenInfo.toggle()
                                } label: {
                                    Image(systemName: "info.circle")
                                        .position(x: rect.maxX + 12, y: rect.minY) // top-right
                                        .contentShape(Rectangle())
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                    .customAlert(isPresented: $showFrozenInfo, title: "Frozen account", message: "Although your account is frozen, you can still view your upcoming events.", showTwoButtons: false) {showFrozenInfo = false}
                
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
