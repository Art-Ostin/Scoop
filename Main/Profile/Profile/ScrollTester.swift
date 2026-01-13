//
//  ScrollViewTest.swift
//  Scoop
//
//  Created by Art Ostin on 13/01/2026.
//

import SwiftUI

struct ScrollTester: View {
    
    @State var isTopOfScroll = false
    
    var body: some View {
        ScrollView {
            ForEach(0..<100, id: \.self) {_ in 
                Text("Hello World")
            }
        }
        .onScrollGeometryChange(for: Bool.self) { geo in
            let y = geo.contentOffset.y + geo.contentInsets.top
            return y <= 0.5
        } action: { _, isAtTop in
            isTopOfScroll = isAtTop
        }
        .overlay(alignment: .topLeading) {
            Text(isTopOfScroll ? "TOP" : "NOT TOP")
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()
        }
    }
}

#Preview {
    ScrollTester()
}
