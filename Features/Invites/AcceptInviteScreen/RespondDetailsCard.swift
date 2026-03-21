//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondDetailsCard: View {
    
    let event: UserEvent
    
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

extension RespondDetailsCard {
    
    
    private var inviteDetailsScreen: some View {
        VStack {
            HStack {
                Text(event.type.description.emoji)
                Text(event.type.description.label)
                Spacer()
                
            }
            .font(.custom("SFProRounded-Bold", size: 24))
            
            Text(event.type.howItWorks(userEvent: event))
        }
    }
    
    
}
