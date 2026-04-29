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
        HStack (alignment: .bottom, spacing: 6) {
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
            .glassIfAvailable(RoundedRectangle(cornerRadius: 24), isClear: false)
            .lineSpacing(4)
            .focused(isFocused)
            .lineLimit(1...5)
    }
    
    private var sendMessageView: some View {
        Button {
            Task { try await sendMessage() }
        } label: {
            Image("SendArrow")
                .scaleEffect(0.8)
                .frame(width: 44, height: 44)
                .background(
                    text.isEmpty ? Color.grayBackground : Color.accent,
                    in: Circle()
                )
                .shadow(color: .black.opacity(text.isEmpty ? 0 : 0.1), radius: 3, y: 2)
        }
    }
    
    private func sendMessage() async throws {
        let savedText = text
        text = ""
        try await vm.sendMessage(text: savedText)
    }
}
