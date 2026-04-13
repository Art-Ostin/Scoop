//
//  RespondMessageBubble.swift
//  Scoop
//
//  Created by Art Ostin on 07/04/2026.
//

import SwiftUI

struct RespondTextBubble: View {
    
    @Binding var showMessageScreen: Bool
    @State var isTextBelow = false
    
    let message: String
    let isMyChat: Bool
    
    var isNewTime: Bool = false
    var showRespondButton: Bool = false
        
    var body: some View {
        Button {
            showMessageScreen = true
        } label: {
            (
                Text(message)
                +
                Text(showRespondButton ? "  Respond" : "")
                    .foregroundStyle(isNewTime ? .accent: .appGreen)
                    .font(.body(12, .bold))
            )
                .font(.body(14, .medium))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                .lineSpacing(3)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(messageBackground)
                .background(geometryMeasure)
                .overlay(alignment: .bottomTrailing) { messageBubbleAction }
                .frame(maxWidth: .infinity, alignment: isMyChat ? .leading : .trailing)
                .padding(.leading, 14)
                .multilineTextAlignment(.leading)
                .padding((isMyChat ? .leading : .trailing), 16)
        }
        .disabled(!isMyChat && !showRespondButton)
    }
}

extension RespondTextBubble {
        
    private var messageBackground: some View {
        bubbleShape
            .fill(isMyChat ? .white : Color(red: 0.93, green: 0.93, blue: 0.93))
            .overlay {
                bubbleShape.stroke (
                    isMyChat ? isNewTime ? Color.accent.opacity(0.5) : Color.appGreen : Color.grayPlaceholder.opacity(0.1),
                    style: StrokeStyle(lineWidth: 1, lineJoin: .round)
                )
            }
    }
    
    private var bubbleShape: MessageBubbleShape {
        MessageBubbleShape(
            topLeadingRadius: 12,
            bottomLeadingRadius: isMyChat ? 12 : 0,
            bottomTrailingRadius: isMyChat ? 0 : 12,
            topTrailingRadius: 12,
            tail: isMyChat ? .trailing : .leading)
    }
    
    private var geometryMeasure: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { updateTimePlacement(bubbleWidth: proxy.size.width) }
                .onChange(of: proxy.size.width) { _, w in updateTimePlacement(bubbleWidth: w) }
                .onChange(of: message) { _, _ in updateTimePlacement(bubbleWidth: proxy.size.width) }
        }
    }
    
    private func updateTimePlacement(bubbleWidth: CGFloat) {
        let textWidth = max(0, bubbleWidth - 32)
        let metrics = textLayoutMetrics(text: message, width: textWidth, font: UIFont.body(16, .regular))
//
        isTextBelow = metrics.lineCount <= 1 || metrics.trailingSpace < 50
    }
    
    private var messageBubbleAction: some View  {
        Text(isMyChat ? "Edit" : "")
            .font(.body(10, .bold))
            .padding(.horizontal, 10)
            .kerning(0.3)
            .foregroundStyle(isNewTime ? Color.accent : Color.appGreen)
            .padding(.bottom, 4)
    }
}
