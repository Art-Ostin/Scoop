//
//  GenericScrollScreen.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

enum Page: String, Hashable {
    case meet = "Meet"
    case meeting = "Meeting"
    case matches = "Matches"
    
    var image: Image  {
        switch self {
            case .meet:
            return Image(systemName: "info.circle")
        case .meeting:
            return Image(systemName: "info.circle")
        case .matches:
            return Image(systemName: "gear")
        }
    }
}

struct CustomTabPage<Content: View>: View {
    
    @State var scrollViewOffset: CGFloat = 0
    @State var topSafeArea: CGFloat = 0
    @State var showPageInfo = false
    
    let page: Page
    let content: Content
    
    init(page: Page, content: @escaping () -> Content) {
        self.page = page
        self.content = content()
    }
    
    var body: some View {
            ScrollView {
                ZStack(alignment: .top) {
                    tabArea
                    TabTitle(page: page, offset: $scrollViewOffset)
                        .padding(.top, 48)
                }
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
    CustomTabPage(page: .meet) {
        Text("Hello World")
    }
}

struct TopSafeAreaTest: PreferenceKey {
    
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}

extension CustomTabPage {
    
    @ViewBuilder
    var tabArea: some View {
        TabButton(image: page.image, isPresented: $showPageInfo)
            .frame(maxWidth: .infinity, alignment: .trailing)
        
    }
    
}
