//
//  DeclineButton.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

struct DeclineButton: View {
    private let image = "DeclineIconBlack"
    let onTap: () -> Void

    var body: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), size: .large, press: .grow) {
            onTap()
        } label: {
//            Image(systemName: "xmark")
//                .font(.body(18, .bold))
            Image(image)
                .resizable()
                .frame(width: 27, height: 27)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 0)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 0)
        }
    }
}

/*
 
 
 Button(action: onTap) {
     Image(image)
         .frame(width: 44, height: 44) //Geometry: circular tap-target diameter
         .background(Circle().fill(Color.appCanvas))
         .circleStroke(lineWidth: 1, color: Color.border)
         .contentShape(Circle())
 }
 .shrinkButton(shadow: .button, tint: .black)

 */
