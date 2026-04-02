//
//  ChatMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct MessageBubbleView: View {
    
    @State var isTimeBelow: Bool = true

    let chat: MessageModel
    let newAuthor: Bool
    let nextIsNewAuthor: Bool
    let isMyChat: Bool
    
    var isInviteMessage: Bool = false
    
    var backgroundColor: Color {
        isMyChat && !isInviteMessage ? Color.accent :  Color(uiColor: .systemGray6).opacity(0.8)
    }
    
    var body: some View {
        Text(chat.content)
            .font(isInviteMessage ?.body(14, .regular) : .body(16, .medium))
            .foregroundStyle(isMyChat && !isInviteMessage ? Color.white : Color.black)
            .lineSpacing(5)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .padding(.bottom, isTimeBelow && !isInviteMessage ? 12 : 0)
            .background (messageCorners)
            .background(geometryMeasure)
            .overlay(alignment: .bottomTrailing) {  if !isInviteMessage { hourMessageSent} }
            .overlay(alignment: isMyChat ? .bottomTrailing : .bottomLeading) {
                messageTriangle
            }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .padding(.horizontal, isInviteMessage ? 0 : 24)
            .padding(isMyChat ? .leading : .trailing, (isInviteMessage ? 0 : 48))
            .padding(.bottom, nextIsNewAuthor ? 12 : 0)
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



struct NewMessageTriangle : View {
    let color: Color
    let isMyChat: Bool
    
    var body: some View {
        MessageTriangle(radius: 4)
            .scaleEffect(x: isMyChat ? 1 : -1, y: 1)
            .foregroundStyle(color)
            .frame(width: 10, height: 15)
            .offset(x: isMyChat ? 10 : -10)
    }
}



extension MessageBubbleView {
    
    @ViewBuilder
    private var messageTriangle: some View {
        if nextIsNewAuthor {
            MessageTriangle(radius: 4)
                .scaleEffect(x: isMyChat ? 1 : -1, y: 1)
                .foregroundStyle(backgroundColor)
                .frame(width: 10, height: 15)
                .offset(x: isMyChat ? 10 : -10)
        }
    }
    
    private var hourMessageSent: some View  {
        Text(FormatEvent.hourTime(chat.dateCreated ?? Date()))
            .font(.body(10, .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .kerning(1)
            .foregroundStyle(isMyChat ? Color.white.opacity(0.7) : Color.gray.opacity(0.8))
    }
    
    private var messageCorners: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: isMyChat ? 16 : (newAuthor ? 16 : 4),
            bottomLeadingRadius: isMyChat ? 16 : (nextIsNewAuthor ? 0 : 4),
            bottomTrailingRadius: isMyChat ? (nextIsNewAuthor ? 0 : 4): 16,
            topTrailingRadius: isMyChat ? (newAuthor ? 16 : 4) : 16,
            style: .continuous
        )
        .fill(backgroundColor)
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

