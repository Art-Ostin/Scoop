//
//  BlurBackground.swift
//  Scoop
//
//  Created by Art Ostin on 03/09/2026.
//

import SwiftUI

struct BlurBackground: View {
    
    let image: UIImage
    let rect: CGRect
    
    let blurRadius: CGFloat = 10
    
    var body: some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .padding(-blurRadius)
            }
            .blur(radius: blurRadius)
            .mask {
                let area = rect.insetBy(dx: -4, dy: 0)//Extra padding beyond the name
                Capsule()
                    .frame(width: area.width, height: area.height)
                    .position(x: area.midX, y: area.midY)
                    .blur(radius: 6)
            }
            .allowsHitTesting(false)
    }
}

extension View {
    func blurBackground(rect: CGRect?, image: UIImage) -> some View {
        overlay {
            if let rect, !rect.isEmpty {
                BlurBackground(image: image, rect: rect)
            }
        }
    }
}
