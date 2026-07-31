//
//  InviteCardShell.swift
//  Scoop Test
//
//  Created by Art Ostin on 30/07/2026.
//

import SwiftUI


struct InvitePopupBackground: View {
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .ignoresSafeArea()
    }
}



//All that is not on the actual InviteCard
struct InviteCardBackground: ViewModifier {
    
    private let shape = RoundedRectangle(cornerRadius: CornerRadius.xl)
    var isConfirming: Bool
    var isInvite: Bool = false
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.sm)
            .background(Color.appCanvas, in: shape)
            .clipShape(shape)
            .stroke(CornerRadius.xl, lineWidth: 1, color: Color.fillGray)
            .shadow(.softFloating)
            .padding(.horizontal, 10)
            .padding(.top, isInvite ? 0 : (isConfirming ? 40 : 48))
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
        .padding(.top, Spacing.xl) // 36
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
        .padding(.horizontal, Spacing.sm) // 12
    }
}
