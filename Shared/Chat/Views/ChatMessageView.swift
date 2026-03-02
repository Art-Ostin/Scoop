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
    private let textHorizontalInsets: CGFloat = 32 // .padding(.horizontal) = 16 + 16
    private let messageUIFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        
    
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
            .padding(.bottom, isTimeBelow ? 16 : 0)
            .background (
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: isMyChat ? 16 : 0,
                    bottomTrailingRadius: isMyChat ? 0 : 16,   // <- sharp corner
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
                    .font(.body(12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .kerning(1)
                    .foregroundStyle(Color.grayText)
            }
            .overlay(alignment: isMyChat ?  .bottomTrailing : .bottomLeading) {
                RoundedTriangle(radius: 4)
                    .scaleEffect(x: isMyChat ? 1 : -1, y: 1)
                    .foregroundStyle(backgroundColor)
                    .frame(width: 10, height: 15)
                    .offset(x: isMyChat ? 10 : -10)
            }
            .frame(maxWidth: .infinity, alignment: isMyChat ? .trailing : .leading)
            .padding(.horizontal, 24)
            .padding(.leading, isMyChat ? 60 : 0)
            .padding(.trailing, isMyChat ? 0 : 60)
    }
    
    private func updateTimePlacement(bubbleWidth: CGFloat) {
        let textWidth = max(0, bubbleWidth - textHorizontalInsets)
        let trailingGap = trailingSpaceInLastLine(text: chat.content, width: textWidth, font: messageUIFont)
        
        
        
        
        if chat.content.count < 35 {
            isTimeBelow = true
        } else {
            isTimeBelow = trailingGap < minInlineGap
        }
    }

    private func trailingSpaceInLastLine(text: String, width: CGFloat, font: UIFont) -> CGFloat {
        guard !text.isEmpty, width > 0 else { return width }

        let attr = NSAttributedString(string: text, attributes: [.font: font])
        let storage = NSTextStorage(attributedString: attr)
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.lineBreakMode = .byWordWrapping

        storage.addLayoutManager(layout)
        layout.addTextContainer(container)
        layout.ensureLayout(for: container)

        var lastUsedRect = CGRect.zero
        let glyphs = layout.glyphRange(for: container)
        layout.enumerateLineFragments(forGlyphRange: glyphs) { _, usedRect, _, _, _ in
            lastUsedRect = usedRect
        }

        return max(0, width - lastUsedRect.maxX)
    }
}

#Preview {
    ChatMessageView(chat: ChatMessageModel.mockChatMessages[0], userId: "user_arthur")
}
