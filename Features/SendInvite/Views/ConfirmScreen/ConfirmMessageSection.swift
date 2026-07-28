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
    
    @State private var messageHeight: CGFloat = 0
    
    var body: some View {
        if let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messageText(message: message)
        } else {
            noMessagePlaceholder
        }
    }
}

extension ConfirmMessageSection {
    
    private func messageText(message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .regular, design: .default))
            .italic()
            .foregroundStyle(Color.textSecondary)
            .lineSpacing(6)
            .getHeight($messageHeight)
            .offset(y: messageLineCount == 3 ? -Spacing.xs : 0)
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
        }
    }
    
    private var messageLineCount: Int {
        guard messageHeight > 0 else { return 0 }
        let lineHeight = UIFont.systemFont(ofSize: 14).lineHeight
        return Int(((messageHeight + 6) / (lineHeight + 6)).rounded())
    }
    
}
