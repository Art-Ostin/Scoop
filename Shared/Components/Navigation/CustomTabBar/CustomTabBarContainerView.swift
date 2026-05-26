//
//  CustomTabBarContainerView.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct CustomTabBarContainerView<Content: View>: View {

    @Binding var selection: AppTab
    let tabs: [AppTab]
    @ViewBuilder let content: (AppTab) -> Content

    @State private var isTabBarHidden = false

    init(
        selection: Binding<AppTab>,
        tabs: [AppTab] = AppTab.allCases,
        @ViewBuilder content: @escaping (AppTab) -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                ForEach(tabs) { tab in
                    content(tab)
                        .opacity(selection == tab ? 1 : 0)
                        .allowsHitTesting(selection == tab)
                }
            }
            .ignoresSafeArea()

            CustomTabBarView(tabs: tabs, selection: $selection)
                .opacity(isTabBarHidden ? 0 : 1)
                .allowsHitTesting(!isTabBarHidden)
                .animation(.easeInOut(duration: 0.2), value: isTabBarHidden)
        }
        .onPreferenceChange(TabBarVisibilityPreferenceKey.self) { value in
            isTabBarHidden = value
        }
    }
}

#Preview {
    CustomTabBarContainerView(selection: .constant(.meet), tabs: [.meet, .events, .pastEvents]) { tab in
        switch tab {
        case .meet:       Color.red
        case .events:     Color.green
        case .pastEvents: Color.blue
        default:          Color.gray
        }
    }
}
