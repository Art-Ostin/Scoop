//
//  CardBackground.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

//Used for the SendInvite and AcceptInvite popupCards
extension View {
    func cardBackground(radius: CGFloat = 30, color: Color = .accent) -> some View {
        self
            .background (
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.appCanvas)
                    .rectangleStroke(radius: 30, lineWidth: 1, color: Color.grayBackground)
                    .cardShadow(color: .accent)
            )
            .morphCardAnchor() //Sets it as destination view
    }
}
