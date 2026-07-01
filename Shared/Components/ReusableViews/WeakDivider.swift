//
//  WeakDivider.swift
//  Scoop Test
//
//  Created by Art Ostin on 16/06/2026.
//

import SwiftUI

struct LightDivider: View {

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .foregroundStyle(Color(white: 0.86))
            .frame(height: 1 / displayScale) //exactly one physical pixel — crisp & identical on every device
            .frame(maxWidth: .infinity)
    }
}
