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
            .foregroundStyle(Color(red: 0.91, green: 0.91, blue: 0.91))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

struct LightDivider: View {

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .foregroundStyle(Color(white: 0.84))
            .frame(height: 1/displayScale) //exactly 1.5 physical pixels — identical on every device
            .frame(maxWidth: .infinity)
    }
}
