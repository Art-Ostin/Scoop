//
//  MessageSection.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct MessageSection: View {
    
    @Bindable var vm: ChatViewModel
    
    let idx: Int
    let message: MessageModel
    
    var isMyChat: Bool {vm.userId == message.authorId}
    var newAuthor: Bool {checkIfNewAuthor() }
    var nextIsNewAuthor: Bool  {checkIfNextIsNewAuthor()}
    var newDay: Bool { isNewDay()}
    
    var body: some View {
        VStack(spacing: 16) {
            if  newDay{
                ChatDayDivider(date: message.dateCreated)
            }
            MessageBubbleView(chat: message, newAuthor: newAuthor, nextIsNewAuthor: nextIsNewAuthor, isMyChat: isMyChat)
        }
    }
}

extension MessageSection {
    
    func isNewDay() -> Bool {
        guard idx > 0 else {return true}
        guard let lastMessageDay = vm.messages[idx - 1].dateCreated else {return false}
        guard let newMessageDay = message.dateCreated else {return false}
        return !Calendar.current.isDate(lastMessageDay, inSameDayAs: newMessageDay)
    }
    
    func checkIfNewAuthor() -> Bool {
        return idx == 0 || vm.messages[idx - 1].authorId != message.authorId
    }
    
    func checkIfNextIsNewAuthor() -> Bool {
        idx == vm.messages.count - 1 || vm.messages[idx + 1].authorId != message.authorId
    }
}
