//
//  GenericScrollScreen.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

enum Page: String, Hashable {
    
    case meet, invites, meetingNoEvent, meetingEvent, pastMatches, editProfile
    
    var title: String {
        switch self {
        case .meetingEvent, .meetingNoEvent:
            return "Meeting"
        case .editProfile:
            return "Edit Profile"
        case .pastMatches:
            return "Message"
        default:
            return self.rawValue.capitalized
        }
    }
}













struct CustomTabPage<Content: View>: View {

    @State var scrollViewOffset: CGFloat = 0
    @Binding var tabAction: Bool

    let page: Page
    let content: Content

    init(page: Page,
         tabAction: Binding<Bool> = .constant(false),
         @ViewBuilder content: @escaping () -> Content) {
        self.page = page
        _tabAction = tabAction
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            ScrollView {
                VStack(spacing: 36) {
                    headerBar
                        .padding(.horizontal, page == .pastMatches ? 16 : 0)
                    content
                }
                .padding(.horizontal, page != .pastMatches ? 20 : 0)
                .padding(.bottom, 48)
            }
            .customScrollFade(height: topInset + 48, showFade: scrollViewOffset < 0, edge: .top)
            .overlay(alignment: .top) { scrollNavBar(topInset: topInset) }
            .scrollClipDisabled(page == .meet || page == .meetingEvent)
            .coordinateSpace(name: page)
            .onPreferenceChange(TitleOffsetsKey.self) { value in
                scrollViewOffset = value[page] ?? 0
            }
            .preference(key: ScrollNavBarVisibleKey.self, value: scrollViewOffset < 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appCanvas.ignoresSafeArea())
            .scrollIndicators(.never)
        }
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

    private func scrollNavBar(topInset: CGFloat) -> some View {
        Text(page.title)
            .font(.body(17, .bold))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .frame(height: (topInset) + 48, alignment: .bottom)
            .opacity(withAnimation(.easeInOut(duration: 0.2)) { scrollViewOffset < 0 ? 1 : 0 })
            .ignoresSafeArea(edges: .all)
    }
    
    private var tabTitle: some View {
        Text(page.title)
            .font(.title())
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(Double(scrollViewOffset) / 70)
            .measure(key: TitleOffsetsKey.self) { geo in
                [page: geo.frame(in: .named(page)).maxY]}
            .foregroundStyle(Color.black)
    }
    
    @ViewBuilder
    private var tabButton: some View {
        Group {
            switch page {
            case .meet, .meetingNoEvent, .invites:
                TabInfoButton(showScreen: $tabAction)
                
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
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
