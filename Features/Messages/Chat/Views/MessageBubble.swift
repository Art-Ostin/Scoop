//
//  ChatMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

//Simplify KEY!!! Not using IsInviteMessage Here anymore

import SwiftUI
import UIKit


struct MessageBubbleView: View {
    private let bubbleBorderWidth: CGFloat = 1
    
    @State var isTimeBelow: Bool = true
    @State private var inlineTimeReservation: CGFloat = 0
    @State private var maxBubbleWidth: CGFloat = 0

    let chat: MessageModel
    let newAuthor: Bool
    let nextIsNewAuthor: Bool
    let isMyChat: Bool

    var isInviteMessage: Bool = false
    var bottomSpacing: CGFloat? = nil

    var includeStroke: Bool { isInviteMessage ? true : false}
    
    var strokeColor: Color  {
        isMyChat ? Color.accent.opacity(0.5) : Color.grayPlaceholder.opacity(0.1)
    }

    private var bubbleContentLeadingPadding: CGFloat {
        isInviteMessage ? 8 : 16
    }

    private var bubbleContentTrailingPadding: CGFloat {
        isInviteMessage ? 20 : 16 + inlineTimeReservation
    }
    
    var backgroundColor: Color {
        isInviteMessage ? isMyChat ? .white : Color(red: 0.93, green: 0.93, blue: 0.93) : isMyChat ? Color.accent :  Color(uiColor: .systemGray6).opacity(0.8)
    }
    
    var body: some View {
        Text(chat.content)
            .font(.body(isInviteMessage ? 14 : 16, .medium))
            .foregroundStyle(isMyChat && !isInviteMessage ? Color.white : isInviteMessage ?  Color(red: 0.2, green: 0.2, blue: 0.2) : Color.black)
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

    private func textLayoutMetrics(text: String, width: CGFloat, font: UIFont) -> (lineCount: Int, trailingSpace: CGFloat) {
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
            .foregroundStyle(isInviteMessage ? Color.accent : isMyChat ? Color.white.opacity(0.7) : Color.gray.opacity(0.8))
    }
    
    private var bubbleShape: MessageBubbleShape {
        MessageBubbleShape(
            topLeadingRadius: isMyChat ? (isInviteMessage ? 12 : 16) : (newAuthor ? (isInviteMessage ? 12 : 16) : 4),
            bottomLeadingRadius: isMyChat ? (isInviteMessage ? 12 : 16) : (nextIsNewAuthor ? 0 : isInviteMessage ? 12 : 4),
            bottomTrailingRadius: isMyChat ? (nextIsNewAuthor ? 0 : 4): (isInviteMessage ? 12 : 16),
            topTrailingRadius: isMyChat ? (newAuthor ? (isInviteMessage ? 12 : 16) : 4) : (isInviteMessage ? 12 : 16),
            tail: nextIsNewAuthor ? (isMyChat ? .trailing : .leading) : .none
        )
    }
    
    private var geometryMeasure: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { updateTimePlacement(bubbleWidth: proxy.size.width) }
                .onChange(of: proxy.size.width) { _, w in updateTimePlacement(bubbleWidth: w) }
                .onChange(of: chat.content) { _, _ in updateTimePlacement(bubbleWidth: proxy.size.width) }
        }
    }

    private var parentWidthMeasure: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    maxBubbleWidth = proxy.size.width
                    updateTimePlacement(bubbleWidth: proxy.size.width)
                }
                .onChange(of: proxy.size.width) { _, w in
                    maxBubbleWidth = w
                    updateTimePlacement(bubbleWidth: w)
                }
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



struct NewMessageBubble: View {
    let text: String
    let time: String
    let isMyChat: Bool
    let showsTail: Bool

    init(text: String, time: String, isMyChat: Bool = false, showsTail: Bool = true) {
        self.text = text
        self.time = time
        self.isMyChat = isMyChat
        self.showsTail = showsTail
    }

    init(chat: MessageModel, isMyChat: Bool, showsTail: Bool = true) {
        self.text = chat.content
        self.time = FormatEvent.hourTime(chat.dateCreated ?? Date())
        self.isMyChat = isMyChat
        self.showsTail = showsTail
    }

    var body: some View {
        Text(text)
            .font(.body(16, .medium))
            .foregroundStyle(isMyChat ? Color.white : Color.black)
            .lineSpacing(5)
            .padding(.leading, leadingPadding)
            .padding(.trailing, trailingPadding)
            .padding(.top, 10)
            .padding(.bottom, 18)
            .background(messageBackground)
            .overlay(alignment: .bottomTrailing) {
                Text(time)
                    .font(.body(10, .regular))
                    .kerning(1)
                    .foregroundStyle(isMyChat ? Color.white.opacity(0.7) : Color.gray.opacity(0.8))
                    .padding(.trailing, isMyChat && showsTail ? 26 : 12)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .padding(.horizontal, 24)
            .padding(isMyChat ? .leading : .trailing, 48)
    }

    private var bubbleTail: MessageBubbleTail {
        guard showsTail else { return .none }
        return isMyChat ? .trailing : .leading
    }

    private var bubbleShape: NewMessageBubbleShape {
        NewMessageBubbleShape(tail: bubbleTail)
    }

    private var messageBackground: some View {
        bubbleShape.fill(isMyChat ? Color.accent : Color(uiColor: .systemGray6).opacity(0.8))
    }

    private var leadingPadding: CGFloat {
        isMyChat ? 16 : (showsTail ? 30 : 16)
    }

    private var trailingPadding: CGFloat {
        isMyChat ? (showsTail ? 74 : 60) : 60
    }
}

struct NewMessageBubbleShape: Shape {
    var tail: MessageBubbleTail = .leading
    var cornerRadius: CGFloat = 18
    var tailWidth: CGFloat = 14
    var tailHeight: CGFloat = 15

    func path(in rect: CGRect) -> Path {
        switch tail {
        case .leading:
            leadingTailPath(in: rect)
        case .trailing:
            leadingTailPath(in: rect).applying(
                CGAffineTransform(translationX: rect.minX + rect.maxX, y: 0)
                    .scaledBy(x: -1, y: 1)
            )
        case .none:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .path(in: rect)
        }
    }

    private func leadingTailPath(in rect: CGRect) -> Path {
        let tailWidth = min(tailWidth, max(0, rect.width * 0.2))
        let tailHeight = min(tailHeight, max(0, rect.height * 0.7))
        let bodyMinX = rect.minX + tailWidth
        let bodyMaxX = rect.maxX
        let bodyWidth = max(0, bodyMaxX - bodyMinX)
        let radius = min(cornerRadius, bodyWidth / 2, rect.height / 2)

        guard bodyWidth > 0, rect.height > 0 else { return Path() }

        var path = Path()
        path.move(to: CGPoint(x: bodyMinX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: bodyMaxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: bodyMaxX, y: rect.minY + radius),
            control: CGPoint(x: bodyMaxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: bodyMaxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: bodyMaxX - radius, y: rect.maxY),
            control: CGPoint(x: bodyMaxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: bodyMinX + radius, y: rect.maxY))

        let tip = CGPoint(x: rect.minX + 1, y: rect.maxY)
        let shoulder = CGPoint(x: bodyMinX, y: rect.maxY - tailHeight)

        path.addCurve(
            to: tip,
            control1: CGPoint(x: bodyMinX + 8, y: rect.maxY),
            control2: CGPoint(x: rect.minX + 7, y: rect.maxY)
        )
        path.addCurve(
            to: shoulder,
            control1: CGPoint(x: rect.minX + 7, y: rect.maxY - 2),
            control2: CGPoint(x: bodyMinX, y: rect.maxY - 7)
        )
        path.addLine(to: CGPoint(x: bodyMinX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: bodyMinX + radius, y: rect.minY),
            control: CGPoint(x: bodyMinX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
