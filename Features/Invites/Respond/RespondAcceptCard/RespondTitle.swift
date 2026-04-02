//
//  RespondTitle.swift
//  Scoop
//
//  Created by Art Ostin on 02/04/2026.
//

import SwiftUI

struct RespondTitle: View {
    
    @Binding var isFlipped: Bool
    let vm: RespondViewModel
    var event: UserEvent {vm.respondDraft.event}
    
    var body: some View {
        
        HStack(spacing: 16) {
            eventTitle
            eventTypeButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension RespondTitle {
    
    
    private var eventTitle: some View {
        HStack(spacing: 8) {
            CirclePhoto(image: vm.image, showShadow: false, height: 30)
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
                    .font(.body(16, .medium))
                
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.grayText).opacity(0.8)
                    .font(.body(14, .medium))
                    .offset(y: -4)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: 110, alignment: .trailing)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    
}
