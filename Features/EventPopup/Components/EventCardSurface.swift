//
//  EventCardSurface.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

//The colouredBackground surface with the glass Effect
struct EventCardSurface: ViewModifier {
    let tint: Color
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.sm)
            .clipShape(.rect(cornerRadius: CornerRadius.xl))
            .containerGlassEffect(tint: Color.appCanvas, clipped: true, shape: .rect(cornerRadius: CornerRadius.xl))
            .shadow(.softFloating)
            .padding(.horizontal, 10)
            .padding(.top, Spacing.md)
            .background(alignment: .top) {
                LinearGradient(
                    colors: [tint.opacity(0.5), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 150)
            } //The tinted Background ontop of the glass
    }
}

//The dismiss chevron `.eventZoom` draws below its card — stationary, never riding the drag or the flight
struct EventDismissButton: View {
    var visible: Bool = true
    let onTap: () -> ()
    var body: some View {
        ScoopButton(shape: Circle(), action: { onTap() }) {
            Image(systemName: "chevron.down")
                .font(.body(17))
                .fontWeight(.heavy)
                .frame(width: 45, height: 45)
        }
        .opacityPop(visible: visible)
        .allowsHitTesting(visible)
        .animation(.transition, value: visible)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
        .padding(.horizontal, Spacing.sm) // 12
    }
}
