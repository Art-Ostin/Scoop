//
//  InviteCardShell.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/07/2026.
//

import SwiftUI


struct InvitePopupBackground: View {

    var tint: Color?

    var body: some View {
        Rectangle()
            .fill(.thinMaterial)
            .fill(tint?.opacity(0.2) ?? .clear)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
    }
}

struct InviteCardBackground: ViewModifier {

    //Geometry: card inset from the screen edge — off the 4pt scale, matched to the Meet card.
    //Shared with the invite flight chassis (SendInviteContainer) so the two cards can't drift.
    static let horizontalInset: CGFloat = 10
    static let topInset = Spacing.md

    private let shape = RoundedRectangle(cornerRadius: CornerRadius.xl)
    var isInvite: Bool = false

    let tint: Color

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.sm)
            .clipShape(shape)
            //clipped: only the declared .softFloating below — the unclipped material's
            //built-in halo made this card heavier than its token, and made the popup
            //flight's landing (which lerps into .softFloating exactly) harden at the end
            .containerGlassEffect(tint: Color.appCanvas, clipped: true, shape: shape)
            .shadow(.softFloating)
            .padding(.horizontal, Self.horizontalInset)
            .padding(.top, Self.topInset)
    }
}

struct InviteSeamWash: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(alignment: .top) {
                LinearGradient(colors: [tint.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
            }
    }
}


struct BottomBackButton: View {

    var visible: Bool = true
    let onTap: () -> ()
    
    var body: some View {
        ScoopButton(shape: Circle(), action: { onTap() }) {
            Image(systemName: "chevron.down")
                .font(.body(17))
                .fontWeight(.heavy)
                .frame(width: 45, height: 45)
        }
        .opacityPop(visible: visible)
        .allowsHitTesting(visible)
        .animation(.transition, value: visible)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
        .padding(.horizontal, Spacing.sm) // 12
    }
}
