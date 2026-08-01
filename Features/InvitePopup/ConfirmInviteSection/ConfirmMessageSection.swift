//
//  ConfirmMessageSection.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct ConfirmMessageSection: View {
    
    let message: String?
    
    @Binding var showMessageScreen: Bool
    
    let isConfirmSend: Bool //No edit if not confirm send

    var body: some View {
        Group {
            if let message = checkMessage {
                messageText(message: message)
            } else {
                noMessagePlaceholder
            }
        }
        .padding(.horizontal, Spacing.margin)
        .containerRelativeFrame(.horizontal, alignment: .leading)
    }
}

extension ConfirmMessageSection {
    
    private func messageText(message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .regular, design: .default))
            .italic()
            .foregroundStyle(Color.textSecondary)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottomTrailing) {editMessageButton}
    }
    
    private var editMessageButton: some View {
        HStack(spacing: 2) {
            Text("Edit")
                .font(.body(12, .medium))
            
            Image("EditButtonBlack")
                .scaleEffect(0.8, anchor: .top)
        }
        .shrinkPress {showMessageScreen = true}
    }
    
    private var noMessagePlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Improve your invite with a message")
                .font(.body(13, .medium))
                .foregroundStyle(Color.textSecondary)

            Text("Add a message")
                .foregroundStyle(Color.textSecondary)
                .font(.body(14, .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.fillGray, in: .rect(cornerRadius: 12))
                .shrinkPress {
                    showMessageScreen = true
                }
        }
    }

    private var checkMessage: String? {
        if let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        } else {
            return nil
        }
    }
}
