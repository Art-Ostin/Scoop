//
//  CustomTabBarView.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct CustomTabBarView: View {

    let tabs: [AppTab]
    @Binding var selection: AppTab
    @Namespace private var namespace

    var body: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                tabBar(tab: tab)
                    .onTapGesture { selection = tab }
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
        .animation(.snappy(duration: 0.2), value: selection)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBarView(tabs: [.meet, .events, .pastEvents], selection: .constant(.meet))
     }
}

extension CustomTabBarView {

    private func tabBar(tab: AppTab) -> some View {
        tab.customIcon(selected: selection == tab)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if selection == tab {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .padding(.horizontal, 1)
                            .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                    }
                }
            )
    }
}
