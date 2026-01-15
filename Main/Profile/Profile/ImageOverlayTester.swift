//
//  ImageOverlayTester.swift
//  Scoop
//
//  Created by Art Ostin on 15/01/2026.
//

import SwiftUI

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct ImageOverlayTester: View {
    var body: some View {
        let monkey = Image("Monkey")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)

        ZStack {
            monkey

            Text("hello World")
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .opacity(0.9)
                .background {
                    VisualEffectBlur(style: .systemThinMaterial) // try .systemMaterial, .systemUltraThinMaterial, etc.
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .opacity(0.9)
                        .overlay {
                            // optional: soften/brighten/darken without harsh edges
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.08))
                        }
                }
        }
    }
}


#Preview {
    ImageOverlayTester()
}
