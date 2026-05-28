//
//  MeetInfoCover.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/05/2026.
//

import SwiftUI

struct MeetInfoCover: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 48) {
                MeetInfoCoverScrollView()
                responseInfo
                    .padding(.horizontal, 24)
                meetInfo
                    .padding(.horizontal, 24)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            howItWorksTitle
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .modifier(SoftScrollEdgeEffect())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .scrollIndicators(.hidden)
    }
}

private struct SoftScrollEdgeEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
    }
}

extension MeetInfoCover {

    private var howItWorksTitle: some View {
        ZStack {
            Text("How it Works")
                .font(.title(17, .bold))
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(y: 2)
            
            DismissButton {dismiss()}
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var responseInfo: some View {
        VStack(spacing: 36) {
            VStack(spacing: 24) {
                Text("2. Response")
                    .font(.title(24, .bold))
                    .kerning(1.1)

                
                Text("They can accept, decline, or propose a new time for you to respond to.")
                    .font(.body(18, .regular))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .kerning(1.1)

                
            }
            Image("CoolGuys")
        }
    }
    
    
    private var meetInfo: some View {
        VStack(spacing: 36) {
            VStack(spacing: 24) {
                Text("3. Meet")
                    .font(.title(24, .bold))
                    .kerning(1.1)

                
                Text("Once someone accepts, the event is created. Meet at the agreed time and place.")
                    .font(.body(18, .regular))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .kerning(1.1)

                
            }
            VStack(spacing: 24) {
                Image("CoolGuys")
                
                Text("*You can message once an event is accepted, to help find each other")
                    .font(.body(15, .regular))
                    .kerning(1.1)
            }
        }
    }
}

