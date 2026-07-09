//
//  MessageInputBar.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct MessageInputBar: View {
    @Bindable var vm: ChatViewModel
    @State var text = ""
    private let messageAnimation = Animation.spring(response: 0.32, dampingFraction: 0.86)

    var isFocused: FocusState<Bool>.Binding

    var body: some View {
            HStack(alignment: .bottom, spacing: 6) {
                chatTextField
                sendMessageView
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        
            .padding(.bottom, isFocused.wrappedValue ? 12 : 0)
            .padding(.top, 12) // determines how much above the fade gradient goes ontop of the view
        
            //When no keyboard want it to ignore safe area. When is keyboard, bottom of fade is keyboard so don't ignore safe area
            .background(isFocused.wrappedValue ? nil : fadeGradient.ignoresSafeArea())
            .background(isFocused.wrappedValue ? fadeGradientFocused.offset(y: 2) : nil) //Offset needed as keyboard is rounded
    }
}

extension MessageInputBar {
    
    private var chatTextField: some View {
        TextField("Message...", text: $text, axis: .vertical)
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .lineSpacing(2.5)
            .lineLimit(1...5)
            .focused(isFocused)
            .glassEffectIfAvailable(clear: false, interactive: true, shape: RoundedRectangle(cornerRadius: CornerRadius.xl))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
            .onTapGesture { isFocused.wrappedValue = true }
    }
    
    @ViewBuilder
    private var sendMessageView: some View {
        let color = text.isEmpty ? Color.fillGray : Color.accent
        let elevation: Elevation? = text.isEmpty ? nil : .customGlassShadow

        ScoopButton(style: .tinted(color, shadow: elevation), shape: Circle(), size: .large) {
            Task { try await sendMessage() }
        } label: {
            Image("SendArrow")
                .scaleEffect(0.8)
        }
        .disabled(text.isEmpty)
    }
    
    private func sendMessage() async throws {
        let savedText = text
        text = ""
        try await vm.sendMessage(text: savedText)
    }
    
    private var fadeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .appCanvas.opacity(0.0), location: 0.0),
                .init(color: .appCanvas.opacity(0.5), location: 0.2),
                .init(color: .appCanvas.opacity(0.65), location: 0.4),
                .init(color: .appCanvas.opacity(0.75), location: 0.6),
                .init(color: .appCanvas.opacity(0.85), location: 0.85),
                .init(color: .appCanvas, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    //Sharper Gradient needed when focused
    private var fadeGradientFocused: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .appCanvas.opacity(0.0), location: 0.0),
                .init(color: .appCanvas.opacity(0.5), location: 0.2),
                .init(color: .appCanvas.opacity(0.7), location: 0.4),
                .init(color: .appCanvas.opacity(0.85), location: 0.6),
                .init(color: .appCanvas, location: 0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

