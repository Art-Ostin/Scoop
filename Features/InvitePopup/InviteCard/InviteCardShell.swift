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
            .background(Color.appCanvas, in: shape)//Clip before the fill, so the carousel can't cut the card's rim
            //No .glassEffect on the card — keep it that way. It renders BEHIND this opaque fill, so it
            //paints nothing, but it still stacks with the .clearGlass buttons inside (options, back
            //chevron) and washes them into milky frosted discs.
//            .stroke(CornerRadius.xl, lineWidth: 1, color: tint)
            .shadow(.softFloating)
            .padding(.horizontal, 10)
            .padding(.top, 16) //Consistent 24 top padding works well (regardless of confirm screen or not)
    }
}


//The card's image → rows seam. Owned by the card and pinned to the top of the rows region,
//so no page motion can open a canvas-coloured gap under the carousel: every page meets the
//image on one colour. Matches the wash the image section sits on.
struct InviteSeamWash: ViewModifier {

    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(alignment: .top) {
                LinearGradient(colors: [tint.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 50)
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

/*
 //            .stroke(CornerRadius.xl, lineWidth: 1, color: Color.fillGray)

 */
