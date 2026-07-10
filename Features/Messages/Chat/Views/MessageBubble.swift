//
//  ChatMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit

struct MessageBubbleView: View {

    //Injected
    let chat: ChatMessage
    let newAuthor: Bool
    let nextIsNewAuthor: Bool
    let isMyChat: Bool
    var isInviteMessage: Bool = false
    var bottomSpacing: CGFloat? = nil

    //Local view state
    @State private var isTimeBelow: Bool = true
    @State private var inlineTimeReservation: CGFloat = 0
    @State private var maxBubbleWidth: CGFloat = 0
    @State private var bubbleContentWidth: CGFloat = 0
    private let bubbleBorderWidth: CGFloat = 1

    var includeStroke: Bool { isInviteMessage ? true : false}

    var strokeColor: Color  {
        isMyChat ? Color.accent.opacity(0.5) : Color.border.opacity(0.1)
    }

    private var bubbleContentLeadingPadding: CGFloat {
        isInviteMessage ? 8 : 16
    }

    private var bubbleContentTrailingPadding: CGFloat {
        isInviteMessage ? 20 : 16 + inlineTimeReservation
    }

    var backgroundColor: Color {
        isMyChat ? (isInviteMessage ? Color.white : Color.accent) : Color.fillGray
    }

    var body: some View {
        Text(chat.content)
            .font(.body(isInviteMessage ? 14 : 16, .medium))
            .foregroundStyle(isMyChat && !isInviteMessage ? Color.white : Color.textPrimary)
            .lineSpacing(isInviteMessage ? 3 : 5)
            .padding(.leading, bubbleContentLeadingPadding)
            .padding(.trailing, bubbleContentTrailingPadding)
            .padding(.vertical, isInviteMessage ? 4 : 10)
            .padding(.bottom, isTimeBelow ? 12 : 0)
            .background(messageBackground)
            .background(geometryMeasure)
            .overlay(alignment: .bottomTrailing) {  hourMessageSent }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .background(parentWidthMeasure)
            .padding(.horizontal, isInviteMessage ? 0 : 24)
            .padding(isMyChat ? .leading : .trailing, (isInviteMessage ? 0 : 48))
            .padding(.bottom, bottomSpacing ?? (nextIsNewAuthor ? (isInviteMessage ? 0 : 12) : 0))
    }

    private func updateTimePlacement(bubbleWidth: CGFloat) {
        guard !isInviteMessage else {
            let textWidth = max(0, bubbleWidth - 32)
            let metrics = textLayoutMetrics(text: chat.content, width: textWidth, font: UIFont.body(16, .regular))
            isTimeBelow = metrics.lineCount <= 1 || metrics.trailingSpace < 50
            return
        }

        let timeWidth = inlineTimeBadgeWidth
        let cap = maxBubbleWidth > 0 ? maxBubbleWidth : bubbleWidth
        let inlineWidth = max(0, cap - 32 - timeWidth)
        let inlineMetrics = textLayoutMetrics(text: chat.content, width: inlineWidth, font: UIFont.body(16, .regular))

        if inlineMetrics.lineCount <= 1 {
            isTimeBelow = false
            inlineTimeReservation = timeWidth
            return
        }

        let wrapWidth = max(0, cap - 32)
        let wrapMetrics = textLayoutMetrics(text: chat.content, width: wrapWidth, font: UIFont.body(16, .regular))
        inlineTimeReservation = 0
        isTimeBelow = wrapMetrics.trailingSpace < timeWidth
    }

    private var inlineTimeBadgeWidth: CGFloat {
        let timeText = FormatEvent.hourTime(chat.dateCreated ?? Date())
        let attr = NSAttributedString(
            string: timeText,
            attributes: [
                .font: UIFont.body(10, .regular),
                .kern: 1
            ]
        )
        return ceil(attr.size().width) + 6
    }
}

extension MessageBubbleView {
    private var messageBackground: some View {
        bubbleShape
            .fill(backgroundColor)
            .overlay {
                if includeStroke {
                    bubbleShape.stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: bubbleBorderWidth, lineJoin: .round)
                    )
                }
            }
    }

    @ViewBuilder
    private var hourMessageSent: some View  {
        let text: String = isInviteMessage && isMyChat ? "Edit note" : isInviteMessage ? "" : FormatEvent.hourTime(chat.dateCreated ?? Date())
        Text(text)
            .font(.body(10, isInviteMessage ? .bold : .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, isInviteMessage ? 0 : 6)
            .kerning(isInviteMessage ? 0.3 : 1)
            .foregroundStyle(isInviteMessage ? Color.textAccent : isMyChat ? Color.white.opacity(0.7) : Color.textTertiary)
    }

    private enum BubbleRadius {
        static let invite: CGFloat = 12
        static let full: CGFloat = 10
        static let tight: CGFloat = 4
        static let joined: CGFloat = 0
    }

    private var outerRadius: CGFloat {
        isInviteMessage ? BubbleRadius.invite : BubbleRadius.full
    }

    private var innerRadius: CGFloat {
        isInviteMessage ? BubbleRadius.invite : BubbleRadius.tight
    }

    private var bubbleShape: MessageBubbleShape {
        MessageBubbleShape(
            topLeadingRadius: isMyChat ? outerRadius : (newAuthor ? outerRadius : BubbleRadius.tight),
            bottomLeadingRadius: isMyChat ? outerRadius : (nextIsNewAuthor ? BubbleRadius.joined : innerRadius),
            bottomTrailingRadius: isMyChat ? (nextIsNewAuthor ? BubbleRadius.joined : BubbleRadius.tight) : outerRadius,
            topTrailingRadius: isMyChat ? (newAuthor ? outerRadius : BubbleRadius.tight) : outerRadius,
            tail: nextIsNewAuthor ? (isMyChat ? .trailing : .leading) : .none
        )
    }

    private var geometryMeasure: some View {
        Color.clear
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w in
                bubbleContentWidth = w
                updateTimePlacement(bubbleWidth: w)
            }
            .onChange(of: chat.content) { _, _ in updateTimePlacement(bubbleWidth: bubbleContentWidth) }
    }

    private var parentWidthMeasure: some View {
        Color.clear
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w in
                maxBubbleWidth = w
                updateTimePlacement(bubbleWidth: w)
            }
    }
}

func textLayoutMetrics(text: String, width: CGFloat, font: UIFont) -> (lineCount: Int, trailingSpace: CGFloat) {
    guard !text.isEmpty, width > 0 else { return (1, width) }
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 5
    let attr = NSAttributedString(
        string: text,
        attributes: [
            .font: font,
            .paragraphStyle: paragraph
        ]
    )
    let storage = NSTextStorage(attributedString: attr)
    let layout = NSLayoutManager()
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.lineBreakMode = .byWordWrapping

    storage.addLayoutManager(layout)
    layout.addTextContainer(container)
    layout.ensureLayout(for: container)

    var lineCount = 0
    var lastUsedRect = CGRect.zero
    let glyphs = layout.glyphRange(for: container)
    layout.enumerateLineFragments(forGlyphRange: glyphs) { _, usedRect, _, _, _ in
        lineCount += 1
        lastUsedRect = usedRect
    }

    return (max(1, lineCount), max(0, width - lastUsedRect.maxX))
}
