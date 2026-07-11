//
//  AppTabBarView.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct AppTabBarView: View {
    @State private var tabSelection: AppTab = .meet

    var body: some View {
        CustomTabBarContainerView(selection: $tabSelection, tabs: [.meet, .events, .pastEvents]) { _ in
            Color.appCanvas
        }
    }
}

#Preview {
    AppTabBarView()
}
