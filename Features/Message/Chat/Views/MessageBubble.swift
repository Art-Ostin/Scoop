//
//  ChatMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct MessageBubbleView: View {
    private let bubbleBorderWidth: CGFloat = 1
    
    @State var isTimeBelow: Bool = true

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
    
    var backgroundColor: Color {
        isInviteMessage ? isMyChat ? .white : Color(red: 0.93, green: 0.93, blue: 0.93) : isMyChat ? Color.accent :  Color(uiColor: .systemGray6).opacity(0.8)
    }
    
    var body: some View {
        Text(chat.content)
            .font(.body(isInviteMessage ? 14 : 16, .medium))
            .foregroundStyle(isMyChat && !isInviteMessage ? Color.white : isInviteMessage ?  Color(red: 0.2, green: 0.2, blue: 0.2) : Color.black)
            .lineSpacing(isInviteMessage ? 3 : 5)
            .padding(.horizontal, isInviteMessage ? 6 : 16)
            .padding(.leading, isInviteMessage ? 2 : 0)
            .padding(.vertical, isInviteMessage ? 4 : 10)
            .padding(.bottom, isTimeBelow ? 12 : 0)
            .background(messageBackground)
            .background(geometryMeasure)
            .overlay(alignment: .bottomTrailing) {  hourMessageSent }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .padding(.horizontal, isInviteMessage ? 0 : 24)
            .padding(isMyChat ? .leading : .trailing, (isInviteMessage ? 0 : 48))
            .padding(.bottom, bottomSpacing ?? (nextIsNewAuthor ? (isInviteMessage ? 0 : 12) : 0))
    }
    
    private func updateTimePlacement(bubbleWidth: CGFloat) {
        let textWidth = max(0, bubbleWidth - 32)
        let metrics = textLayoutMetrics(text: chat.content, width: textWidth, font: UIFont.body(16, .regular))

        isTimeBelow = metrics.lineCount <= 1 || metrics.trailingSpace < 50
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
            bottomLeadingRadius: isMyChat ? (isInviteMessage ? 12 : 16) : (nextIsNewAuthor ? 0 : 4),
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
}
