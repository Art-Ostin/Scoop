//
//  ChatMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct MessageBubbleView: View {
    
    let chat: MessageModel
    
    let newAuthor: Bool
    let nextIsNewAuthor: Bool
    let isMyChat: Bool
    
    
    var backgroundColor: Color {
        isMyChat ? Color.accent :  Color(uiColor: .systemGray6).opacity(0.8)
    }
    
    @State var isTimeBelow: Bool = true
    private let minInlineGap: CGFloat = 50
    private let textHorizontalInsets: CGFloat = 32 // .padding(.horizontal) = 16 + 16
    private let timeBelowPadding: CGFloat = 12
    private let messageUIFont = UIFont.body(16, .regular)
        
    
    var body: some View {
        let timeString = chat.dateCreated?.formatted(
            Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        ) ?? ""
        
        Text(chat.content)
            .font(.body(16, .medium))
            .foregroundStyle(isMyChat ? Color.white : Color.black)
            .lineSpacing(5)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .padding(.bottom, isTimeBelow ? timeBelowPadding : 0)
            .background (
                //Gets the right cornerRadius
                UnevenRoundedRectangle(
                    topLeadingRadius: isMyChat ? 16 : (lastIsDifferentUser ? 16 : 4),
                    bottomLeadingRadius: isMyChat ? 16 : (nextIsDifferentUser ? 0 : 4),
                    bottomTrailingRadius: isMyChat ? (nextIsDifferentUser ? 0 : 4): 16,
                    topTrailingRadius: isMyChat ? (lastIsDifferentUser ? 16 : 4) : 16,
                    style: .continuous
                )
                .fill(backgroundColor)
            )
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { updateTimePlacement(bubbleWidth: proxy.size.width) }
                        .onChange(of: proxy.size.width) { _, w in updateTimePlacement(bubbleWidth: w) }
                        .onChange(of: chat.content) { _, _ in updateTimePlacement(bubbleWidth: proxy.size.width) }
                }
            )
            .overlay(alignment: .bottomTrailing) {
                Text(timeString)
                    .font(.body(10, .regular))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .kerning(1)
                    .foregroundStyle(isMyChat ? Color.white.opacity(0.7) : Color.gray.opacity(0.8))
            }
            .overlay(alignment: isMyChat ?  .bottomTrailing : .bottomLeading) {
                if nextIsDifferentUser {
                    RoundedTriangle(radius: 4)
                        .scaleEffect(x: isMyChat ? 1 : -1, y: 1)
                        .foregroundStyle(backgroundColor)
                        .frame(width: 10, height: 15)
                        .offset(x: isMyChat ? 10 : -10)
                }
            }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .padding(.horizontal, 24)
            .padding(.leading, isMyChat ? 48 : 0)
            .padding(.trailing, isMyChat ? 0 : 48)
            .padding(.bottom, nextIsNewAuthor ? 12 : 0)
    }
    
    private func updateTimePlacement(bubbleWidth: CGFloat) {
        let textWidth = max(0, bubbleWidth - textHorizontalInsets)
        let metrics = textLayoutMetrics(text: chat.content, width: textWidth, font: messageUIFont)

        if metrics.lineCount <= 1 {
            isTimeBelow = true
        } else {
            isTimeBelow = metrics.trailingSpace < minInlineGap
        }
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


struct RoundedTriangle: Shape {
    var radius: CGFloat = 40

    func path(in rect: CGRect) -> Path {
        let a = CGPoint(x: rect.minX, y: rect.maxY) // bottom-left
        let b = CGPoint(x: rect.minX, y: rect.minY) // top-left
        let c = CGPoint(x: rect.maxX, y: rect.maxY) // bottom-right (rounded)

        let hyp = hypot(b.x - c.x, b.y - c.y)
        let r = min(radius, rect.width / 2, hyp / 2)

        // Points where the rounded corner starts/ends
        let onBottom = CGPoint(x: c.x - r, y: c.y)
        let onHypotenuse = CGPoint(
            x: c.x + (b.x - c.x) * (r / hyp),
            y: c.y + (b.y - c.y) * (r / hyp)
        )

        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        p.addLine(to: onHypotenuse)
        p.addQuadCurve(to: onBottom, control: c) // round bottom-right
        p.addLine(to: a)
        p.closeSubpath()
        return p
    }
}
