//
//  DeclineButton.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

struct DeclineButton: View {
    private let image = "DeclineIcon"
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(image)
                .frame(width: 44, height: 44) //Geometry: circular tap-target diameter
                .background(Circle().fill(Color.appCanvas))
                .circleStroke(lineWidth: 1, color: Color.border)
                .contentShape(Circle())
        }
        .shrinkButton(shadow: .button, tint: .black)
    }
}
