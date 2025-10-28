//
//  TabTitle.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI

enum Page: String, Hashable {
    case meet = "Meet"
    case meeting = "Meeting"
    case matches = "Matches"
}

struct TabTitle: View {
    let page: Page
    @Binding var offset: CGFloat
    
    var body: some View {
        Text(page.rawValue)
            .font(.custom("SFProRounded-Bold", size: 32))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(Double(offset) / 70)
            .background (
                GeometryReader { proxy in
                    Color.clear.preference (
                        key: TitleOffsetsKey.self,
                        value: [page: proxy.frame(in: .named(page)).maxY]
                    )
                }
            )
    }
}

struct TitleOffsetsKey: PreferenceKey {
    static var defaultValue: [Page: CGFloat] = [:]
    static func reduce(value: inout [Page: CGFloat], nextValue: () -> [Page: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
