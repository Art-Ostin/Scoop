//
//  ChatMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatMessageView: View {
    
    let chat: ChatMessageModel
    
    let userId: String
    
    var showTriangle: Bool = false
    
    var isMyChat: Bool {
        chat.authorId == userId
    }
    
    var backgroundColor: Color {
        isMyChat ? Color.accent.opacity(0.05) : Color(uiColor: .systemGray6)
    }
    
    @State var isTimeBelow: Bool = true
    private let minInlineGap: CGFloat = 50
    private let textHorizontalInsets: CGFloat = 32 
    private let timeBelowPadding: CGFloat = 12
    private let messageUIFont = UIFont.body(16, .regular)
        
    
    var body: some View {
        let timeString = chat.dateCreated?.formatted(
            Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        ) ?? ""
        
        Text(chat.content)
            .font(.body(16, .regular))
            .foregroundStyle(Color.black)
            .lineSpacing(5)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .padding(.bottom, isTimeBelow ? timeBelowPadding : 0)
            .background (
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: isMyChat ? 16 : (showTriangle ? 0 : 16),
                    bottomTrailingRadius: isMyChat ? (showTriangle ? 0 : 16) : 16,   // <- sharp corner
                    topTrailingRadius: 16,
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
                    .font(.body(9, .regular))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .kerning(1)
                    .foregroundStyle(Color.grayText.opacity(0.8))
            }
            .overlay(alignment: isMyChat ?  .bottomTrailing : .bottomLeading) {
                if showTriangle {
                    RoundedTriangle(radius: 4)
                        .scaleEffect(x: isMyChat ? 1 : -1, y: 1)
                        .foregroundStyle(backgroundColor)
                        .frame(width: 10, height: 15)
                        .offset(x: isMyChat ? 10 : -10)
                }
            }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .padding(.horizontal, 24)
            .padding(.leading, isMyChat ? 60 : 0)
            .padding(.trailing, isMyChat ? 0 : 60)
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

#Preview {
    ChatMessageView(chat: ChatMessageModel.mockChatMessages[0], userId: "user_arthur")
}
