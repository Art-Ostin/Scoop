//
//  GenericScrollScreen.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI
enum Page: String, Hashable {
    case Meet, Meeting, Matches

    var image: Image {
        switch self {
        case .Meet, .Meeting:
            Image(systemName: "info.circle")
        case .Matches:
            Image(systemName: "gear")
        }
    }
}

struct CustomTabPage<Content: View>: View {
    @State var scrollViewOffset: CGFloat = 0
    @State var topSafeArea: CGFloat = 0
    @Binding var TabAction: Bool
    
    let page: Page
    let content: Content
    init(page: Page, TabAction: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.page = page
        _TabAction = TabAction
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                TabButton(page: page, isPresented: $TabAction)
                TabTitle(page: page, offset: $scrollViewOffset)
                    .padding(.top, 48)
            }
            .padding(.horizontal, 24)
            content
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
        .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.background)
        .measure(key: TopSafeAreaTest.self) { geo in
            geo.safeAreaInsets.top
        }
        .onPreferenceChange(TopSafeAreaTest.self) { newSafeArea in
            topSafeArea = newSafeArea
        }
    }
}

struct TopSafeAreaTest: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}
