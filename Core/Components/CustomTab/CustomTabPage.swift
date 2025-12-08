//
//  GenericScrollScreen.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

struct CustomTabPage: View {
    
    @State var scrollViewOffset: CGFloat = 0
    
    @State var topSafeArea: CGFloat = 0
    
    @State var showTestScreen = false
    let page: Page
    //    let content : content
    var body: some View {
        ZStack {
            ScrollView {
                ZStack(alignment: .top) {
                    tabArea
                    
                    TabTitle(page: page, offset: $scrollViewOffset)
                        .padding(.top, 48)
                }
            }
            if showTestScreen {
                TestScreen(showTestScreen: $showTestScreen)
            }
        }
        .overlay(alignment: .top) {
            ScrollNavBar(title: page.rawValue, topSafeArea: topSafeArea)
                .opacity(scrollViewOffset < 0 ? 1 : 0)
                .ignoresSafeArea(edges: .all)
        }
        .scrollIndicators(.never)
        .coordinateSpace(name: page)
        .onPreferenceChange(TitleOffsetsKey.self) { value in
            scrollViewOffset = value[page] ?? 0
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .measure(key: TopSafeAreaTest.self) { geo in
            geo.safeAreaInsets.top
        }
        .onPreferenceChange(TopSafeAreaTest.self) { newSafeArea in
            topSafeArea = newSafeArea
        }
        .background(Color.blue)
    }
}

#Preview {
    CustomTabPage(page: .meet)
}

struct TopSafeAreaTest: PreferenceKey {
    
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}

extension CustomTabPage {
    
    var tabArea: some View {
        HStack {
            TabButton(image: Image(systemName: "gear"), isPresented: $showTestScreen)
            Spacer()
            TabButton(image: Image(systemName: "checkmark"), isPresented: $showTestScreen)
        }
        .frame(maxWidth: .infinity)
    }
    
}
