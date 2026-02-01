//
//  AppTabBarView.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct AppTabBarView: View {
    @State var tabSelection: TabBarItem = .meet

    var body: some View {
        CustomTabBarContainerView(selection: $tabSelection) {
            Color.background
                .tabBarItem(.meet, selection: $tabSelection)
            
            Color.background
                .tabBarItem(.events, selection: $tabSelection)
            
            Color.background
                .tabBarItem(.matches, selection: $tabSelection)
        }
    }
}

#Preview {
    AppTabBarView()
}
