//
//  ToggleDropDownButton.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownButton: View {
    
    @Binding var isExpanded: Bool
        
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
                Image(systemName: "chevron.down")
                    .font(.body(17, .bold))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .foregroundStyle(Color.accent)
                    .padding(12)
                    .contentShape(Rectangle())
                    .padding(-12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DropDownButton(isExpanded: .constant(false))
}


