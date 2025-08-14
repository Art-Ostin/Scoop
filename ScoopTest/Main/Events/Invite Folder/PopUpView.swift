//
//  PopUpView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct PopUpView: View {
    
    var image: UIImage
    
    var event: UserEvent
        
    let vm: ProfileViewModel
    
    var body: some View {
        
        VStack(spacing: 24) {
            HStack {
                CirclePhoto(image: image)
                Text("\(String(describing: event.otherUserName))'s Invite")
            }
            Text(vm.dep.eventManager.formatTime(date: event.time))
            
            if let message = event.message {
                Text(message)
            }
            
            ActionButton(text: "Accept", isInvite: true) {
                if let id = event.id {
                    Task { try await vm.dep.eventManager.updateStatus(eventId: id, to: .accepted) }
                    vm.showInvite.toggle()
                }
            }
        }
        .padding([.bottom, .horizontal], 32)
        .padding(.top, 24)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
                .background(Color.background)
        )
    }
}

