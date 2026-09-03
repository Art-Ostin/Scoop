//
//  EventBackdrop.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

//Coloured Backdrop
struct EventBackdrop: View {
    var tint: Color?
    var body: some View {
        Rectangle()
            .fill(.thinMaterial)
            .fill(tint?.opacity(0.2) ?? .clear)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
    }
}

//The frosted backdrop `.eventZoom` draws under its card — its opacity rides the flight
struct EventBackdropV2: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
    }
}


