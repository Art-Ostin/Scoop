//
//  Dividers.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct CustomDivider: View {
    var body: some View {
        Rectangle()
            .foregroundStyle(Color.border)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

struct LightDivider: View {

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .foregroundStyle(Color.border)
            .frame(height: 1/displayScale) //exactly 1.5 physical pixels — identical on every device
            .frame(maxWidth: .infinity)
    }
}
