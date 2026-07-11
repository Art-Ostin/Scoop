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
        .padding(Spacing.xs)
        .frame(height: 56)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .compositingGroup()
        .shadow(.floating)
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.sm)
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
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if selection == tab {
                        Capsule()
                            .fill(Color.white)
                            .padding(.horizontal, 1)
                            .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                    }
                }
            )
    }
}
