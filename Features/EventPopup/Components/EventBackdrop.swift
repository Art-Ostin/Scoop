//
//  EventPopupShell.swift
//  Scoop Test
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

//Backdrop currently used in the HistoryContainer
struct EventBackdropV2: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
    }
}


