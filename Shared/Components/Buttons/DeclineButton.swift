//
//  DeclineButton.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

struct DeclineButton: View {
    let image: String = "DeclineIcon"
    let onTap: () -> ()
    var body: some View {
        Image(image)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(Color.appCanvas)
            )
            .circleStroke(lineWidth: 1, color: Color.border)
            .contentShape(Circle())
            .shadow(.button)
            .onTapGesture {onTap()}
            .scaleEffect(1.1)
            .padding(.horizontal, Spacing.margin)
            .padding(.bottom, Spacing.xs)
    }
}
