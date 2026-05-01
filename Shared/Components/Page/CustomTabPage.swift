//
//  GenericScrollScreen.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

struct CustomTabPage<Content: View>: View {
    
    @State var scrollViewOffset: CGFloat = 0
    @Binding var tabAction: Bool

    let page: Page
    let content: Content
    
    init(page: Page, tabAction: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.page = page
        _tabAction = tabAction
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                headerBar
                    .padding(.horizontal, page == .pastMatches ? 16 : 0)
                content
            }
            .padding(.bottom, 48)
        }
        .overlay(alignment: .top) {scrollNavBar}
        .scrollIndicators(.never)
        .scrollClipDisabled(page == .meet)
        .coordinateSpace(name: page)
        .onPreferenceChange(TitleOffsetsKey.self) { value in
            scrollViewOffset = value[page] ?? 0
        }
        .preference(key: ScrollNavBarVisibleKey.self, value: scrollViewOffset < 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, page != .pastMatches ? 16 : 0) //On the Screens 
        .background(Color(red: 0.99, green: 0.98, blue: 0.97))
    }
}

extension CustomTabPage {
    
    private var headerBar: some View {
        ZStack(alignment: .top) {
            tabButton
                .padding(.top, 12)
            tabTitle
                .padding(.top, 60)
        }
    }
    
    private var scrollNavBar: some View {
        GeometryReader { geo in
            ScrollNavBar(title: page.title, topSafeArea: geo.safeAreaInsets.top)
                .opacity(withAnimation(.easeInOut(duration: 0.2)) { scrollViewOffset < 0 ? 1 : 0 })
                .ignoresSafeArea(edges: .all)
        }
    }
    private var tabTitle: some View {
        Text(page.title)
            .font(.custom("SFProRounded-Bold", size: 32))
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(Double(scrollViewOffset) / 70)
            .measure(key: TitleOffsetsKey.self) { geo in
                [page: geo.frame(in: .named(page)).maxY]}
    }
    
    @ViewBuilder
    private var tabButton: some View {
        Group {
            switch page {
            case .meet, .meetingNoEvent, .invites:
                TabInfoButton(showScreen: $tabAction)
                
            case .meetingEvent:
                messageButton
                
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var messageButton: some View {
        Button {
            tabAction = true
        } label: {
//            Image("") //roundMessageIcon
//                .resizable()
//                .scaledToFit()
//                .frame(width: 22, height: 22)
//                .font(.body(17, .bold))
//                .padding(6)
//                .glassIfAvailable(isClear: true)
//                .padding(24) //Expands Tap Area
//                .contentShape(Rectangle())
//                .padding(-24)
        }
    }
}


struct TitleOffsetsKey: PreferenceKey {
    static var defaultValue: [Page: CGFloat] = [:]
    static func reduce(value: inout [Page: CGFloat], nextValue: () -> [Page: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct ScrollNavBarVisibleKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
