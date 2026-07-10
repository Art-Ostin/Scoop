//
//  CirclePhoto.swift
//  Scoop
//
//  Created by Art Ostin on 03/08/2025.
//

import SwiftUI



struct ChangeIcon: View {
    var body: some View {
        Image("EditButton")
        .padding(12)
        .frame(width: 24, height: 24)
        .background (
            Circle()
                .fill(Color.white)
        )
        .padding(6)
    }
}

struct RemoveIcon: View {
    var body: some View {
        Image(systemName: "xmark")
            .font(.body(12, .bold))
            .padding(12)
            .frame(width: 24, height: 24)
            .background (Circle().fill(Color.appCanvas))
            .padding(6)
            .scaleEffect(0.7)
    }
}

