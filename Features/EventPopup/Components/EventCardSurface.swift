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
                .frame(height: 20)
            }
    }
}

//The dismiss chevron `.eventZoom` draws below its card — stationary, never riding the drag or the flight
struct EventDismissButton: View {

    //The row's geometry, named for a caller that takes pictures of the buttons where they stand (the View Event flight)
    static let height: CGFloat = 45 //Geometry: the chevron's disc, which the leading capsule matches
    static let labelPadding = Spacing.md
    static let edgeInset = 10 + Spacing.sm //Geometry: EventCardSurface's 10pt gap, then the row's own

    var visible: Bool = true
    
    let leadingTitle: String?
    
    let onTap: () -> ()
    
    let onLeadingTap: (() -> ())?
    
    var body: some View {
        
        HStack(spacing: Spacing.xs) {
            if let leadingTitle, let onLeadingTap {
                ScoopButton(shape: Capsule(), action: onLeadingTap) {
                    Text(leadingTitle) // "View Event"
                        .font(.body(16, .medium))
                        .padding(.horizontal, Self.labelPadding)
                        .frame(height: Self.height)
                }
                .opacityPop(visible: visible)
                .allowsHitTesting(visible)
                .animation(.transition, value: visible)
            }
            Spacer()
            ScoopButton(shape: Circle(), action: { onTap() }) {
                Image(systemName: "chevron.down")
                    .font(.body(17))
                    .fontWeight(.heavy)
                    .frame(width: Self.height, height: Self.height)
            }
            .opacityPop(visible: visible)
            .allowsHitTesting(visible)
            .animation(.transition, value: visible)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, Self.edgeInset)
        
    }
}
