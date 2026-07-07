//
//  ImageContainer.swift
//  Scoop
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


struct ScoopImage: View {
    
    let image: UIImage
    var aspectRatio: CGFloat = 1/1.08//DefaultAppImage
    var showShadow: Bool = false
    var hPadding: CGFloat = 16 //Default Spacing
    
    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: 16, style: .continuous))
            .cardShadow(showShadow: showShadow)
            .padding(.horizontal, hPadding)
    }
}

extension View {
    
    @ViewBuilder
    func cardShadow(showShadow: Bool) -> some View {
        if showShadow {
            self
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
        } else {
            self
        }
    }
}
