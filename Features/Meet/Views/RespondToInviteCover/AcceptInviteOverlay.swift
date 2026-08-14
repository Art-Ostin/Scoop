//
//  AcceptInviteOverlay.swift
//  Scoop
//
//  Created by Art Ostin on 13/08/2026.
//

import SwiftUI

struct AcceptInviteCard: View {
    
    @State private var angle: Double = 0
    
    @State private var scale: CGFloat = 0.2
    @State private var lift: CGFloat = Spacing.xxxl
    
    
    let animationDuration: CGFloat = 2.5
    
    
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            
            
            ZStack {
                Circle()
                    .fill(.clear)
                    .frame(width: 275, height: 275)
                    .glassEffectIfAvailable(shape: Circle())
                    .shadow(color: .accent.opacity(0.1), radius: 75)

                Image("ProfileMockB")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 225, height: 225)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 0)
                    .modifier(BackfaceCulled(angle: angle))
                
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.1)
            .scaleEffect(scale)
            .offset(y: lift)
            .onAppear {
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 2.5)) { angle = 1800}
                withAnimation(.easeOut(duration: 1.7)) {
                    scale = 1
                    lift  = 0
                }
            }

            Text("You’re Meeting \n Arthur!")
                .font(.title(32, .bold))
                .multilineTextAlignment(.center)
        }
    }
}


#Preview {
    AcceptInviteCard()
}


//Hides it if facing the back
struct BackfaceCulled: ViewModifier, Animatable {
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var facingViewer: Bool {
        let turn = angle.truncatingRemainder(dividingBy: 360)
        let normalized = turn < 0 ? turn + 360 : turn
        return normalized <= 90 || normalized >= 270
    }

    func body(content: Content) -> some View {
        content.opacity(facingViewer ? 1 : 0)
    }
}
