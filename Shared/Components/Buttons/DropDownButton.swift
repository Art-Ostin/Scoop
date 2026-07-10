//
//  ToggleDropDownButton.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownButton: View {
    let isOpen: Bool
    var isAccept: Bool = false
    
    var body: some View {
        Image(isAccept ? "DropDownIconGreen" : "DropdownGray") //GrayIcon //InviteDropdown
            .rotationEffect(.degrees(isOpen ? 90 : 0))
            .animation(.snappy(duration: 0.2, extraBounce: 0.01), value: isOpen)
    }
}



//Old Drop Down Chevron
struct DropDownChevron: View {
    @Binding var showTimePopup: Bool
    
    var body: some View {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTimePopup.toggle()
                }
            } label: {
                Image(systemName:  "chevron.down")
                    .offset(y: 0.5)
                    .font(.body(15, .bold))
                    .rotationEffect(.degrees(showTimePopup ? 180 : 0))
                    .foregroundStyle(Color.textPrimary)
                    .padding(7)
                    .background(
                        Circle().foregroundStyle(.white).opacity(0.7)
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(Color.border.opacity(0.3), lineWidth: 0.5)
                    }
                    .microShadow()
                    .contentShape(Rectangle())
                    .padding(14)
            }
            .buttonStyle(.plain)
            .padding(-14)
    }
}


