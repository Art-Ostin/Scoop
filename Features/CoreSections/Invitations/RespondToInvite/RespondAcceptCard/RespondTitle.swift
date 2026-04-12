//
//  RespondTitle.swift
//  Scoop
//
//  Created by Art Ostin on 02/04/2026.
//

import SwiftUI

struct RespondTitle: View {
    
    @Binding var isFlipped: Bool
    
    let showTimePopup: Bool
    let event: UserEvent
    let image: UIImage
    
    var body: some View {
        
        HStack(spacing: 16) {
            eventTitle
            InviteRespondButton(type: event.type, isFlipped: $isFlipped)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(showTimePopup ? 0.03 : 1)
    }
}

extension RespondTitle {
    
    private var eventTitle: some View {
        HStack(spacing: 11) {
            CirclePhoto(image: image, showShadow: false, height: 25).offset(x: -2)
            Text("Meet \(event.otherUserName)")
                .font(.custom("SFProRounded-Bold", size: 24))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .layoutPriority(1)
    }
}

/*
 
 Image(systemName: "info.circle")
     .foregroundStyle(Color.grayText).opacity(0.8)
     .font(.body(14, .medium))
     .offset(y: -4)
 */
