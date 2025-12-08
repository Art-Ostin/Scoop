//
//  VStackTest.swift
//  Scoop
//
//  Created by Art Ostin on 08/12/2025.
//

import SwiftUI

struct VStackTest: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 200)
                .foregroundStyle(.blue)

            Rectangle()
                .frame(height: 200)
                .foregroundStyle(.orange)

            Rectangle()
                .frame(height: 600)   // ← big one
                .foregroundStyle(.green)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 12)
        .ignoresSafeArea(edges: .bottom)

    }
}

#Preview {
    VStackTest()
}
