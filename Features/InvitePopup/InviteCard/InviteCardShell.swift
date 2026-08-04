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
            //Chained fill: the last one renders ON TOP of the material, which is the only
            //place a pale tint survives — behind it the material washes it out entirely
            .fill(tint?.opacity(0.4) ?? .clear)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
    }
}

//All that is not on the actual InviteCard
struct InviteCardBackground: ViewModifier {
    
    private let shape = RoundedRectangle(cornerRadius: CornerRadius.xl)
    var isInvite: Bool = false

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.sm)
            .background(Color.appCanvas, in: shape)
            .clipShape(shape)
            .shadow(.softFloating)
            .padding(.horizontal, 10)
            .padding(.top, 24) //Consistent 24 top padding works well (regardless of confirm screen or not)
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
