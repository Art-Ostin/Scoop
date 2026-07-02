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
            .foregroundStyle(Color(white: 0.84))
            .frame(height: 1/displayScale) //exactly 1.5 physical pixels — identical on every device
            .frame(maxWidth: .infinity)
    }
}
