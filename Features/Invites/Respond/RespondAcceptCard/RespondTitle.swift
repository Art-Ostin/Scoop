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
            HStack(spacing: 0) {
                Text("\(event.type.description.emoji)\(event.type.description.label)")
                    .font(.body(14, .bold))
                
                Image(systemName: "info.circle")
                    .font(.body(8, .medium))
                    .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
                    .offset(y: -3)
            }
            .padding(6)
            .padding(.leading, 2)
            .padding(.trailing, 2)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color.white.opacity(0.7))
            )
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            .stroke(100, lineWidth: 0.5, color: .grayPlaceholder.opacity(0.3))
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
