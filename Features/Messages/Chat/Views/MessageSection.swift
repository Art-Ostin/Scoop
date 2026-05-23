//
//  MessageSection.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct MessageSection: View {

    @Bindable var vm: ChatViewModel
    let message: MessageModel

    var body: some View {
        VStack(spacing: 16) {
            if vm.isNewDay(for: message) {
                ChatDayDivider(date: message.dateCreated)
            }
            MessageBubbleView(
                chat: message,
                newAuthor: vm.isNewAuthor(for: message),
                nextIsNewAuthor: vm.isNextNewAuthor(for: message),
                isMyChat: vm.isMyChat(message)
            )
        }
    }
}
