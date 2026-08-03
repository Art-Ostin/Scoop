//
//  ConfirmMessageSection.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct ConfirmMessageSection: View {

    //Injected
    let message: String?

    @Binding var showMessageScreen: Bool

    let isConfirmSend: Bool

    
    //Local view state
    @State private var textWidth: CGFloat = 0
    @State private var editSize: CGSize = .zero
    @State private var hasMeasured = false //The button starts below and settles into place — don't animate that

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
        .offset(y: checkMessage == nil  ? 0 : -12)
    }
}

extension ConfirmMessageSection {
    
    private func messageText(message: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(message)
                .font(Self.messageFont)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(Self.messageLineSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .getWidth($textWidth)

            editMessageButton
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                    editSize = size
                    if !hasMeasured { Task { @MainActor in hasMeasured = true } }
                }
                .padding(.top, editFitsOnLastLine ? -editSize.height : Spacing.xs)
        }
        .animation(hasMeasured ? .move : nil, value: editFitsOnLastLine)
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
                .font(.body(13, .regular))
                .foregroundStyle(Color.textSecondary)
            

            Text("Add a message")
                .foregroundStyle(Color.textSecondary)
                .font(.body(14, .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.fillGray.opacity(0.5), in: .capsule)
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


//Tracks and updates where the message section sits
extension ConfirmMessageSection {

    //One pair, so the drawn text and the measured text can't disagree on line breaks
    private static let messageFont: Font = .body(14, .italic)
    private static let measurementFont: UIFont = .body(14, .italic)
    private static let messageLineSpacing: CGFloat = 6

    //Edit rides the last line only on a wrapped message whose final line leaves it room —
    //a single line, or a last line that would run under the button, drops it to its own row.
    private var editFitsOnLastLine: Bool {
        guard let message = checkMessage, editSize.width > 0 else { return false }

        let metrics = message.lineMetrics(
            font: Self.measurementFont,
            lineSpacing: Self.messageLineSpacing,
            width: textWidth
        )

        guard metrics.count >= 2 else { return false }
        return metrics.lastLineWidth + Spacing.sm + editSize.width <= textWidth
    }
}
