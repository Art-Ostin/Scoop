//
//  VStackTest.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

struct VStackTest: View {
    var body: some View {
        VStack {
            Rectangle()
                .frame(height: 200)
                .foregroundStyle(.blue)
                .padding(.top, 12)

            Rectangle()
                .frame(height: 200)
                .foregroundStyle(.orange)

            Rectangle()
                .frame(height: 500)   // ← big one
                .foregroundStyle(.green)
        }
        // Keep the VStack's intrinsic vertical size (200 + 200 + 500),
        // even if it is taller than the screen.
        .fixedSize(horizontal: false, vertical: true)
        // Then pin that taller stack to the top of the available space.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    VStackTest()
}
