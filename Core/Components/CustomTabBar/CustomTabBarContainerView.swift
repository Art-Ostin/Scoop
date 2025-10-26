//
//  CustomTabBarContainerView.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI



struct CustomTabBarContainerView<Content: View>:  View {
    
    @Binding var selection: TabBarItem
    let content: Content
    @State private var tabs: [TabBarItem] = []
    
    public init(selection: Binding<TabBarItem>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .ignoresSafeArea()
            
            CustomTabBarView(tabs: tabs, selection: $selection, localSelection: selection)
        }

        .onPreferenceChange(TabBarItemsPreferenceKey.self) { value in
            self.tabs = value
        }
    }
}

#Preview {
    let tabs: [TabBarItem] = [ .meet, .events, .matches]
    
    CustomTabBarContainerView(selection: .constant(tabs.first!)) {
        Color.red
    }
}
