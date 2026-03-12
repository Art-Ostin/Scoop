//
//  ColorBackground.swift
//  Scoop
//
//  Created by Art Ostin on 12/03/2026.
//

import SwiftUI


extension View {
    func colorBackground(color: Color = Color.background) -> some View {
        self
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.background)
    }
}
