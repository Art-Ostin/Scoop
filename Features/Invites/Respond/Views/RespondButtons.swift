//
//  InviteRespondButtons.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct AddMessageButton: View {
    
    @Binding var showMessageScreen: Bool

    let hasEventMessage: Bool
    
    var body: some View {
        Button {
            showMessageScreen = true
        } label : {
            Image("AddMessageIcon")
                .padding(Spacing.sm)
                .contentShape(Rectangle())
                .padding(-Spacing.sm)
                .padding(Spacing.xs)
                .background(
                    Circle()
                        .foregroundStyle(Color.white).opacity(hasEventMessage ? 0.7 : 0.3)
                )
                .circleStroke(lineWidth: 0.5, color: Color.border.opacity(0.5))
                .shadow(.card, strength: hasEventMessage ? 0 : 1)
        }
    }
}


struct InviteRespondButton: View {
    
    let type: Event.EventType
    let onTap: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.toggle) {
                onTap()
            }
        } label: {
            HStack(spacing: 0) {
                Text("\(type.emoji)\(type.title)")
                    .font(.body(18, .bold))
                
                Image(systemName: "info.circle")
                    .font(.body(10, .medium))
                    .foregroundStyle(Color.textTertiary)
                    .offset(y: -3)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: 110, alignment: .trailing)
        }
        .fixedSize(horizontal: true, vertical: false)
        .buttonStyle(.plain)
    }
}


//Logic for EventTypeButton
struct EventTypeButton: View {
    
    let type: Event.EventType
    @Binding var showInfo: Bool
    
    var longTitle: Bool = false
    
    var body: some View {
        
        Button {
            showInfo.toggle()
        } label: {
            HStack(spacing: Spacing.hairline) {
                Text("\(type.emoji) \(longTitle ? type.longTitle : type.title)")
                    .font(.body(17, .bold))
                Image(systemName: "info.circle")
                    .font(.body(12, .medium))
                    .foregroundStyle(Color.textPlaceholder)
                    .offset(x: 6, y: -3) // so goes slightly outside view
            }
        }
        .shrinkButton()
    }
}
