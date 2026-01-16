//
//  OverlayScreenTest.swift
//  Scoop
//
//  Created by Art Ostin on 16/01/2026.
//

import SwiftUI

struct OverlayScreenTest: View {
    var body: some View {
        ScrollView(.vertical) {
            ForEach(0..<100) {_ in 
                Text("Hello World")
            }
        }
        .overlay(alignment: .bottom) {
            Text("Goodbye Today, Hello Today")
        }
    }
}

#Preview {
    OverlayScreenTest()
}
