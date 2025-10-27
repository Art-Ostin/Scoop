//
//  GenericTest.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI

struct GenericTest<TabBar: View, MainContent: View> : View {
    
    
    let tabBar: TabBar
    let mainContent: MainContent
    
    @State var scrollViewOffset: CGFloat = 0
    
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.background
                ScrollView {
                    VStack(spacing: 36) {
                        VStack(spacing: 0) {
                            tabBar
                            TabTitle(page: .matches, offset: $scrollViewOffset)
                        }
                    }
                }
            }
        }
            .onPreferenceChange(TitleOffsetsKey.self) {value in
                scrollViewOffset = value[.matches] ?? 0
            }
            .coordinateSpace(name: Page.matches)
    }
}

#Preview {
    GenericTest()
}


import SwiftUI
import FirebaseFunctions


struct MatchesView: View {

    
    var body: some View {

            .ignoresSafeArea()
        }
        
        
        .sheet(isPresented: $showSettingsView) {
            SettingsView(vm: SettingsViewModel(authManager: vm.authManager, sessionManager: vm.s))
        }
        .task(id: vm.user) {  image = try? await vm.fetchFirstImage()}
    }
}
