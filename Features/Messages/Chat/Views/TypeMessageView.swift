//
//  TypeMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct TypeMessageView: View {
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
        .padding(.top, 12)
        .padding(.horizontal)
        .padding(.bottom, isFocused.wrappedValue ? 12 : 0)
    }
}

extension TypeMessageView {
    
    private var chatTextField: some View {
        TextField("Message...", text: $text, axis: .vertical)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .lineSpacing(4)
            .lineLimit(1...5)
            .focused(isFocused)
            .glassEffectIfAvailable(clear: false, interactive: true, shape: RoundedRectangle(cornerRadius: 24))
            .contentShape(RoundedRectangle(cornerRadius: 24))
            .onTapGesture { isFocused.wrappedValue = true }
    }
    
    @ViewBuilder
    private var sendMessageView: some View {
        let color = text.isEmpty ? Color.grayBackground : Color.accent
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
}

