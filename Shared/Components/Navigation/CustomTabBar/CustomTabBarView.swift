//
//  CustomTabBarView.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct CustomTabBarView: View {
    
    let tabs: [TabBarItem]
    @Binding var selection: TabBarItem
    @Namespace private var namespace
    @State var localSelection: TabBarItem
    
    @State private var bump = false


    var body: some View {
        tabBarVersion
            .onChange(of: selection) { oldValue, newValue in
                withAnimation(.snappy(duration: 0.2)) {
                    localSelection = newValue
            }
        }
    }
}

#Preview {
    let tabs: [TabBarItem] = [ .meet, .events, .matches]
    VStack {
        Spacer()
        CustomTabBarView(tabs: tabs, selection: .constant(tabs.first!), localSelection: tabs.first!)
     }
}

extension CustomTabBarView {
    
    private func switchToTab(tab: TabBarItem) {
        selection = tab
    }
    
    private func tabBar(tab: TabBarItem) -> some View {
        VStack {
            if localSelection == tab { tab.image } else { tab.imageBlack }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .scaleEffect(localSelection == tab && bump ? 1.18 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: bump)
        .background(
            ZStack {
                if localSelection == tab {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .padding(.horizontal, 1)
                        .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                }
            }
        )
    }
    
    private var tabBarVersion: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                tabBar(tab: tab)
                    .onTapGesture {
                        switchToTab(tab: tab)
                    }
            }
        }
        .padding(8)
        .frame(height: 56)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .compositingGroup()
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 8)
        .padding(.horizontal, 36)
        .padding(.bottom, 12)
    }
}
