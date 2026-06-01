//
//  GlassButton.swift
//  Scoop
//
//  Created by Art Ostin on 01/06/2026.

import SwiftUI

struct GlassButton<Content: View>: View {
    var padding: CGFloat = 0
    var shape: GlassButtonShape = .circle
    
    let action: () -> Void
    var buttonLabel: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                buttonLabel()
                    .padding(padding)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(shape.borderShape)
            .tint(.clear)
            .foregroundStyle(Color.black)
        } else {
            Button(action: action) {
                buttonLabel()
                    .padding(padding + 8)//Keeps size of pre Ios 26 and Ios 26 buttons the same
                    .background(shape.fallbackShape.fill(.ultraThinMaterial).brightness(0.07))
                    .foregroundStyle(Color.black)
            }
            .growButton(shadow: .customGlassShadow)
        }
    }
}

//So I can pass different shapes into the GlassButton as they take different shapes
enum GlassButtonShape {
    case circle
    case capsule
    case roundedRect(CGFloat)

    @available(iOS 26.0, *)
    var borderShape: ButtonBorderShape {
        switch self {
        case .circle:             .circle
        case .capsule:            .capsule
        case .roundedRect(let r): .roundedRectangle(radius: r)
        }
    }

    var fallbackShape: AnyShape {
        switch self {
        case .circle:             AnyShape(Circle())
        case .capsule:            AnyShape(Capsule())
        case .roundedRect(let r): AnyShape(RoundedRectangle(cornerRadius: r))
        }
    }
}

