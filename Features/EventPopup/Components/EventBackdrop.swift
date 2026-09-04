//
//  EventBackdrop.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

//The frosted backdrop `.eventZoom` draws under its card — its opacity rides the flight
struct EventBackdrop: View {
    var body: some View {
        Rectangle()
            .fill(.thinMaterial)
            .background(Color.white.opacity(0.2))
            .ignoresSafeArea()
    }
}
