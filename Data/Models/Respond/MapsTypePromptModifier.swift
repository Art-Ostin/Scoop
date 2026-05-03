//
//  MapsTypePromptModifier.swift
//  Scoop
//
//  Created by Art Ostin on 03/05/2026.
//

import SwiftUI

private struct MapsTypePromptModifier: ViewModifier {
    @Binding var pending: MapsLaunchRequest?
    let defaults: DefaultsManaging

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Open location in",
            isPresented: Binding(
                get: { pending != nil },
                set: { if !$0 { pending = nil } }
            ),
            titleVisibility: .visible,
            presenting: pending
        ) { request in
            Button("Apple Maps") { choose(.appleMaps, request) }
            Button("Google Maps") { choose(.googleMaps, request) }
            Button("Cancel", role: .cancel) { pending = nil }
        }
    }

    private func choose(_ type: PreferredMapType, _ request: MapsLaunchRequest) {
        defaults.updatePreferredMapType(mapType: type)
        MapsRouter.openMaps(
            defaults: defaults,
            item: request.item,
            withDirections: request.withDirections
        )
        pending = nil
    }
}

extension View {
    func mapsTypePrompt(
        pending: Binding<MapsLaunchRequest?>,
        defaults: DefaultsManaging
    ) -> some View {
        modifier(MapsTypePromptModifier(pending: pending, defaults: defaults))
    }
}
