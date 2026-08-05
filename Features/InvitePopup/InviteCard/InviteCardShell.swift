//
//  InviteCardShell.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/07/2026.
//

import SwiftUI


struct InvitePopupBackground: View {

    //The artwork's text tint. Nil keeps the plain frosted backdrop
    var tint: Color?

    var body: some View {
        Rectangle()
            .fill(.regularMaterial)
            .fill(tint?.opacity(0.2) ?? .clear)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
    }
}

//All that is not on the actual InviteCard
struct InviteCardBackground: ViewModifier {
    
    private let shape = RoundedRectangle(cornerRadius: CornerRadius.xl)
    var isInvite: Bool = false

    let tint: Color
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.sm)
            .clipShape(shape)
            .background(Color.appCanvas, in: shape)//Clips the carousel before the glass, so the glass rim isn't cut (and keeps its transitions)
            .glassEffectIfAvailable(tint: .appCanvas, shape: shape) //Canvas-tinted so the card keeps its hue; non-interactive, an interactive glass view claims hitTest over the rows
//            .stroke(CornerRadius.xl, lineWidth: 1, color: tint)
            .shadow(.softFloating)
            .padding(.horizontal, 10)
            .padding(.top, 16) //Consistent 24 top padding works well (regardless of confirm screen or not)
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

/*
 //            .stroke(CornerRadius.xl, lineWidth: 1, color: Color.fillGray)

 */
