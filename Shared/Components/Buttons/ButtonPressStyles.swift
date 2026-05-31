//
//  CustomButtonStyles.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressableLabel(configuration: configuration)
    }

    private struct PressableLabel: View {
        let configuration: Configuration
        @State private var tapTrigger = 0

        var body: some View {
            configuration.label
                .keyframeAnimator(initialValue: PressValues(), trigger: tapTrigger) { content, value in
                    content
                        .scaleEffect(value.scale)
                        .opacity(value.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(0.86, duration: 0.12)                       // down
                        SpringKeyframe(1.06, duration: 0.26, spring: .bouncy)     // overshoot
                        SpringKeyframe(1.0,  duration: 0.22, spring: .smooth)     // settle
                    }
                    KeyframeTrack(\.opacity) {
                        CubicKeyframe(0.65, duration: 0.12)
                        LinearKeyframe(1.0, duration: 0.48)
                    }
                }
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed { tapTrigger += 1 }   // fire once, on press-down only
                }
        }
    }

    struct PressValues {
        var scale = 1.0
        var opacity = 1.0
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { .init() }
}


//Update to mimic Revolut's custom button tap style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(withAnimation(.easeInOut) { configuration.isPressed ? 0.9 : 1 })
            .brightness(configuration.isPressed ? 0.1 : 0)
    }
}


extension View {
    func customButtonStyle() -> some View {
        buttonStyle(PressableButtonStyle())
    }
}




struct CustomButtonStyles: View {
    var body: some View {
        
        Button {
            
        } label: {
            
        }
//        .buttonStyle(.)
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
