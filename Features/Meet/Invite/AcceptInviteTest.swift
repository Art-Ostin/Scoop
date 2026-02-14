//
//  ContentTransitionTest.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI
import Lottie

struct AcceptInviteTest: View {
    @State var showAcceptInviteView: Bool = false
    
    @Namespace private var ns
    
    var body: some View {
        ZStack {
            
            if !showAcceptInviteView {
                CustomScreenCover {}
                RoundedRectangle(cornerRadius: 36)
                    .matchedGeometryEffect(id: "AcceptInvite", in: ns)
                    .frame(height: 400)
                    .frame(width: 365)
                    .foregroundStyle(Color.background)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 6)
            } else {
                ZStack {
                    LottieView(animation: .named("SendingModern.json"))
                        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            showAcceptInviteView.toggle()
        }
        .animation(Animation.easeInOut(duration: 0.9), value: showAcceptInviteView)
    }
}


struct LottieAtFrame: UIViewRepresentable {
    var name: String = "SendingModern"          // optional (default)
    var frame: AnimationFrameTime = 42          // optional (default)
    var paused: Bool = true
    // optional (default)
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let v = LottieAnimationView(name: name)
        v.contentMode = .scaleAspectFit   // or .scaleAspectFill
        v.currentFrame = frame
        if paused { v.pause() }
        return v
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}

