//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondDetailsCard: View {
    
    let event: UserEvent
    @Binding var isFlipped: Bool

    
    var body: some View {
        VStack(spacing: 24) {
            
            Text("Hello World")
            Text("Hello World")
            Text("Hello World")
        }
        .modifier(CardContainerModifier())
    }
}

extension RespondDetailsCard {
    

    private var inviteDetailsTitle: some View {
        HStack {
            Text("\(event.type.description.emoji)  \(event.type.description.label)")
                .font(.custom("SFProRounded-Bold", size: 24))
            
            Spacer()
            
            Button {
                isFlipped = false
            } label: {
                Text("Event")
                    .foregroundStyle(Color.appGreen)
                    .font(.body(16, .bold))
            }
        }
    }

    private var inviteDetailsScreen: some View {
        VStack {
            HStack {
                Text(event.type.description.emoji)
                Text(event.type.description.label)
                Spacer()
                
            }
            
            Text(event.type.howItWorks(userEvent: event))
        }
    }
    
    private var backToEvent: some View {
        Text("Event")
            .foregroundStyle(Color.appGreen)
            .contentShape(.rect)
            .onTapGesture {
                isFlipped.toggle()
            }
    }
}
