//
//  RespondToProfileView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI
import Lottie

struct RespondToProfileView: View {
    
    @Binding var showRespondToProfile: Bool?
    
    let isSent: Bool
    
    let zoomNamespace: Namespace.ID?
    let zoomID: String?
    
    private var zoomKey: String? {
        zoomID.map { "inviteZoom-\($0)" }
    }
    
    @State private var showContent = false
    @State private var cornerRadius: CGFloat = 28



    var body: some View {
        ZStack {
            // Full-screen background (fades in)
            Color.background
                .ignoresSafeArea()
                .opacity(showContent ? 1 : 0)

            // Destination “shape” that the card zooms into
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.background)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .matchedInviteZoom(id: zoomKey, in: zoomNamespace, isSource: false)
                .ignoresSafeArea()

            // Your content (appears after the zoom begins)
            content
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.98)
        }
        .zIndex(10)
        .transition(.opacity.animation(.easeInOut(duration: 0.18)))
        .onAppear {
            showContent = false
            cornerRadius = 28

            // content fades in slightly after the zoom starts
            withAnimation(.easeInOut(duration: 0.18).delay(0.12)) {
                showContent = true
            }

            // square off the corners after the zoom settles (optional, but usually looks better)
            withAnimation(.easeInOut(duration: 0.22).delay(0.28)) {
                cornerRadius = 0
            }
        }
        .onDisappear {
            showContent = false
            cornerRadius = 28
        }
    }

    @ViewBuilder
    private var content: some View {
        if isSent {
            VStack(alignment: .center, spacing: 36) {
                Image("Cool Guys")
                Text("Invite Sent")
                    .font(.body(16, .bold))
            }
        } else {
            VStack(alignment: .center, spacing: 36) {
                Image("Monkey")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Text("Declined")
                    .font(.body(16, .bold))
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func matchedInviteZoom(
        id: String?,
        in namespace: Namespace.ID?,
        isSource: Bool
    ) -> some View {
        if let id, let namespace {
            self.matchedGeometryEffect(id: id, in: namespace, isSource: isSource)
        } else {
            self
        }
    }
}




/*
 
 LottieView(animation: .named("SendAnimation.json"))
     .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
     .resizable()
     .scaledToFit()
     .frame(maxWidth: .infinity)
     .frame(height: 250)
     .offset(y: -24)
 */
