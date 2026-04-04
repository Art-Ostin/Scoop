//
//  RespondTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 04/04/2026.
//

import SwiftUI

struct RespondTypeRow: View {
    
    @Binding var isFlipped: Bool
    
    let type: Event.EventType
    let message: String?
    let showTimePopup: Bool
    
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("\(type.description.emoji)")
            VStack(alignment: .leading, spacing: 4) {
                respondTypeButton
                if let message {messageResponse(message)}
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        }
    }

extension RespondTypeRow {
    
    private var respondTypeButton: some View {
        Button {
            isFlipped.toggle()
        } label: {
            HStack(spacing: 2) {
                Text("\(type.description.label)")
                    .font(.body(16, .medium))
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.grayText).opacity(0.8)
                    .font(.body(14, .medium))
                    .offset(y: -4)
            }
        }
    }
    
    private func messageResponse(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(Color.grayText)
            .opacity(showTimePopup ? 0.1 : 1)
    }
    
}
