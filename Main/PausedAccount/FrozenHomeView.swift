//
//  FrozenHomeView.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

import SwiftUI

struct FrozenHomeView: View {
    
    @State var showSettings: Bool = false
    
    @State private var tabSelection: TabBarItem = .meet
    
    @State private var frozenSelection: Int = 0

    
    var body: some View {
        ZStack {
            if #available(iOS 26.0, *) {TabView(selection: $tabSelection) {
                
                FrozenScreen(tabSelection: $frozenSelection)
                    .tag(TabBarItem.meet)
                    .tabItem { Label("", image: tabSelection == .meet ? "BlackLogo" : "AppLogoBlack")}

                
                FrozenScreen(tabSelection: $frozenSelection)
                    .tag(TabBarItem.events)
                    .tabItem {Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")}

                
                FrozenScreen(tabSelection: $frozenSelection)
                    .tag(TabBarItem.matches)
                    .tabItem {Label("", image: tabSelection == .matches ? "BlackMessage" : "MessageIcon")}
                    .overlay(alignment: .topLeading) {
                        SettingsButton(showSettingsView: $showSettings)
                            .padding(.horizontal)
                    }
            }} else {
                CustomTabBarContainerView(selection: $tabSelection) {
                    FrozenScreen(tabSelection: $frozenSelection)
                        .tabBarItem(.meet, selection: $tabSelection)
                    FrozenScreen(tabSelection: $frozenSelection)
                        .tabBarItem(.events, selection: $tabSelection)
                    FrozenScreen(tabSelection: $frozenSelection)
                        .tabBarItem(.events, selection: $tabSelection)
                        .overlay(alignment: .topLeading) {
                            SettingsButton(showSettingsView: $showSettings)
                                .padding(.horizontal)
                    }
                }
            }
        }
    }
}
