//
//  InfoTest.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI


struct TabButton: View {
    let image: Image
    var body: some View {
        image
            .font(.body(17))
            .padding(6)
            .foregroundStyle(.black)
            .glassIfAvailable()
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 24)
            .padding(.top, 48)
    }
}

extension View {
    @ViewBuilder
    func glassIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}
