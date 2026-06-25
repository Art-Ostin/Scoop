//
//  ImageContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI


extension Image {
    func defaultImage(_ size: CGFloat, _ radius: CGFloat = 18) -> some View {
        self
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0))
            .clipShape(.rect(cornerRadius: radius, style: .continuous))
    }
}
