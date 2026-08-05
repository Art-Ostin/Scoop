//
//  AddMessageFooter.swift
//  Scoop Test
//
//  Created by Art Ostin on 05/08/2026.
//

import SwiftUI

//Own struct: renders in the menu's overlay window, where the dismiss env would otherwise no-op.
struct AddMessageFooter: View {

    @Environment(\.dropdownCustomMenuDismiss) private var menuDismiss

    let message: String
    let corners: RectangleCornerRadii
    let onSelect: () -> Void

    //With no message yet the footer is the row's call to action, so it wears the accent fill.
    private var isCallToAction: Bool { message.isEmpty }

    var body: some View {
        Text(isCallToAction ? "Add a Message" : "Edit Message")
            .foregroundStyle(isCallToAction ? Color.white : Color.textAccent)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.body(16, .bold))
            .kerning(0.5)
            .frame(height: 40)
            .frame(width: SelectTypeView.cardWidth, alignment: .leading)
            .background(accentFill)
            .dropdownCustomMenuFooterPlatter(corners: corners)
            .contentShape(.rect)
            .shrinkPress {
                onSelect()
                Task {
                    try? await Task.sleep(for: .seconds(0.04))
                    menuDismiss(.instant)
                }
            }
    }

    @ViewBuilder
    private var accentFill: some View {
        if isCallToAction {
            UnevenRoundedRectangle(cornerRadii: corners).fill(Color.textAccent)
        }
    }
}
