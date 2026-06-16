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
                .padding(12)
                .contentShape(Rectangle())
                .padding(-12)
                .padding(6)
                .background(
                    Circle()
                        .foregroundStyle(Color.white).opacity(hasEventMessage ? 0.7 : 0.3)
                )
                .stroke(100, lineWidth: 0.5, color: Color.grayPlaceholder.opacity(0.5))
                .shadow(color: .black.opacity(hasEventMessage ? 0 : 0.05), radius: 1, x: 0, y: 1.5)
        }
    }
}


struct InviteRespondButton: View {
    
    let type: Event.EventType
    let onTap: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        } label: {
            HStack(spacing: 0) {
                Text("\(type.emoji)\(type.title)")
                    .font(.body(18, .bold))
                
                Image(systemName: "info.circle")
                    .font(.body(10, .medium))
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
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
            HStack(spacing: 2) {
                Text("\(type.emoji) \(longTitle ? type.longTitle : type.title)")
                    .font(.body(17, .bold))
                Image(systemName: "info.circle")
                    .font(.body(12, .medium))
                    .foregroundStyle(Color(white: 0.8))
                    .offset(x: 6, y: -3) // so goes slightly outside view
            }
        }
        .shrinkButton(shadow: nil)
    }
}
