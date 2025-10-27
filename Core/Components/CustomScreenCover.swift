//
//  CustomScreenCover.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI

struct CustomScreenCover: View {
    let onTap: () -> Void
    var body: some View {
        Rectangle()
            .fill(.thinMaterial)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture { onTap() }
    }
}

#Preview {
    CustomScreenCover(onTap: {})
}
