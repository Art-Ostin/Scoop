//
//  TextPopTransition.swift
//  Scoop Test
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
