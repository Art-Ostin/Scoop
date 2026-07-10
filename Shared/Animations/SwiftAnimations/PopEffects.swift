//
//  TextPopTransition.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2026.
//

import SwiftUI


//To Use:

/* TO USE
 //1. Wrap text in ZStack and give it a and position it
 ZStack {
     Text(text)
         .id(text)
         .transition(.blurReplace.combined(with: .scale(0.9)))
 }
 .frame(width: 280, alignment: .center)

//2. Use this animation to work best, for the actual text change
 private func swap() {
     pop += 1
     withAnimation(.smooth(duration: 0.4).delay(0.12)) {
         //Change Text in HERE
     }
 }
 */

extension View {
    
    func textPopTransition(trigger: Int) -> some View {
        self
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: trigger,
            ) { content, value in
                content
                    .scaleEffect(value.scale)
                    .offset(y: value.yOffset)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.12, duration: 0.16, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.22, spring: .bouncy)
                }

                KeyframeTrack(\.yOffset) {
                    CubicKeyframe(-4, duration: 0.16)
                    SpringKeyframe(0, duration: 0.22)
                }
            }
    }
}

struct AnimationValues {
    var scale = 1.0
    var yOffset = 0.0
}

// MARK:  Default show / dismiss animation
extension Animation {
    static let scoopPop: Animation = .spring(response: 0.35, dampingFraction: 0.7)
}

extension AnyTransition {
    static var scoopPop: AnyTransition {
        AnyTransition(.blurReplace).combined(with: .scale(scale: 0.8, anchor: .top))
    }
}


private struct OpacityPop: ViewModifier {
    var visible: Bool
    var shrunkScale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(visible ? 1 : shrunkScale)
            .opacity(visible ? 1 : 0)
    }
}

extension View {
    func opacityPop(visible: Bool, scale: CGFloat = 0.4) -> some View {
        modifier(OpacityPop(visible: visible, shrunkScale: scale))
    }
}

private struct BlurPop: ViewModifier {
    var visible: Bool
    var shrunkScale: CGFloat
    var blurRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: visible ? 0 : blurRadius)
            .scaleEffect(visible ? 1 : shrunkScale)
            .opacity(visible ? 1 : 0)
            .animation(.scoopPop, value: visible)
    }
}

extension View {
    func blurPop(visible: Bool, scale: CGFloat = 0.7, blur: CGFloat = 8) -> some View {
        modifier(BlurPop(visible: visible, shrunkScale: scale, blurRadius: blur))
    }
}
