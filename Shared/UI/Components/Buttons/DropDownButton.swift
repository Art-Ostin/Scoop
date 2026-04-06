//
//  ToggleDropDownButton.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI


struct DropDownChevron: View {
    @Binding var showTimePopup: Bool
    var body: some View {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTimePopup.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.body(15, .bold))
                    .rotationEffect(.degrees(showTimePopup ? 180 : 0))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .padding(6)
                    .background(
                        Circle().foregroundStyle(.white).opacity(0.7)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1.5)
                    .stroke(100, lineWidth: 0.5, color: .grayPlaceholder.opacity(0.5))
                    .contentShape(Rectangle())
                    .padding(14)
            }
            .buttonStyle(.plain)
            .padding(-14)
    }
}



struct DropDownButton: View {
    
    @Binding var isExpanded: Bool
    
    var isAccept: Bool = false
    var color: Color = .accent
    var showGlass: Bool = false
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            buttonImage
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var buttonImage: some View {
        
        let base = Image(systemName: "chevron.down")
            .font(.body(isAccept ? 15 : 17, .bold))
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .foregroundStyle(isAccept ? .black : color)
            .padding(12)
            .contentShape(Rectangle())
            .padding(-12)
        
        if showGlass {
            base
                .padding(6)
                .glassIfAvailable(Circle(), isClear: true)
                .padding(-6)
                .padding(.vertical, -3)
            
        } else {
            base
        }
    }
    
    private var customButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.body(isAccept ? 15 : 17, .bold))
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                .padding(6)
                .background(
                    Circle().foregroundStyle(.white)
                )
                .surfaceShadow(.floating, strength: 0.5)
                .contentShape(Rectangle())
                .padding(14)     // bigger hit area
        }
        .buttonStyle(.plain)
        .padding(-14)            // cancels layout expansion
    }
}

#Preview {
    DropDownButton(isExpanded: .constant(false))
}


