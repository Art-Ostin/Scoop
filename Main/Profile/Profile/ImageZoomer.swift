//
//  ImageZoomer.swift
//  Scoop
//
//  Created by Art Ostin on 15/01/2026.

import SwiftUI

struct ImageZoomer: View {
    var body: some View {
        ZoomContainer {
            Image("ProfileMockB")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .pinchZoom()
        }
    }
}

#Preview {
    ImageZoomer()
}
