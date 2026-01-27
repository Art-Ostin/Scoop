//
//  ToggleDropDownButton.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct ToggleDropDownButton: View {
    
    @Binding var isExpanded: Bool
    
    @State var showDropDownMenu: Bool = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                showDropDownMenu.toggle()
            }
        } label: {
                Image(systemName: "chevron.down")
                    .font(.body(17, .bold))
                    .rotationEffect(.degrees(showDropDownMenu ? 180 : 0))
                    .foregroundStyle(Color.accent)
                    .padding(12)
                    .contentShape(Rectangle())
                    .padding(-12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ToggleDropDownButton(isExpanded: .constant(true))
}


