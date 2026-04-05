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
            eventTypeButton
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
    
    
    private var eventTypeButton: some View {
        Button {
            isFlipped.toggle()
        } label: {
            HStack(spacing: 2) {
                Text("\(event.type.description.emoji) \(event.type.description.label)")
                    .font(.body(14, .bold))
                    .padding(6)
                    .padding(.horizontal, 4)
                    .stroke(24, lineWidth: 0.75, color: Color(red: 0.8, green: 0.8, blue: 0.8).opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .foregroundStyle(Color.white)
                    )
                    .surfaceShadow(.floating, strength: 0.3)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: 110, alignment: .trailing)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    
}

/*
 
 Image(systemName: "info.circle")
     .foregroundStyle(Color.grayText).opacity(0.8)
     .font(.body(14, .medium))
     .offset(y: -4)
 */
