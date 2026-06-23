//
//  InviteCardEventInfo.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/06/2026.
//

import SwiftUI

struct InviteCardInfo: View {
    
    @Environment(\.timeCustomMenuDismiss) private var timeMenuDismiss
    
    @Binding var draft: RespondDraft

    let lineIconWidth: CGFloat = 20
    
    let eventProfile: EventProfile
    let onRespond: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            eventTypeLine
            eventTimeLine
            eventPlaceLine
        }
        .font(.body(17, .bold))
        .modifier(InviteCardInfoBackground())
        .overlay(alignment: .bottomTrailing) {inviteButton}
        .overlay(alignment: .topTrailing) { infoButton}
    }
}

//Different Views
extension InviteCardInfo {
    
    private var eventTypeLine: some View {
        HStack(spacing: 10) {
            Text(eventProfile.event.type.emoji)
                .font(.body(14))
                .frame(width: 20, alignment: .leading)
            
            Text(eventProfile.event.type.longTitle)
        }
    }
    
    private var eventPlaceLine: some View {
        HStack(spacing: 10) {
            Image("MiniMapIcon")
                .scaleEffect(1.2, anchor: .bottom)
                .frame(width: 20, alignment: .leading)
                .offset(y: 5) // Fine Tuning

            Text(eventProfile.event.location.name ?? "")
                .foregroundStyle(Color.appGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 19)
        }
    }
    
    private var eventTimeLine: some View {
        RespondTimeRow(draft: $draft)
    }
        
    private var infoButton: some View {
        SmallInfoIcon(size: 12, colour: Color(white: 0.75))
            .padding()
            .padding(.trailing, 8)
    }
    
    private var inviteButton: some View {
        InviteButton(
            isInviting: false,
            morphId: eventProfile.event.id,
            isInviteCard: true
        ) {
            onRespond()
        }
        .padding(12)
    }
}

struct InviteCardInfoBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCanvas, in: .rect(cornerRadius: 18))
    }
}

/*
 
 var formattedDay: String {
     if let firstDay = eventProfile.event.proposedTimes.firstAvailableDate {
         let day  = firstDay.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())  // Thursday, Sep 23
         let time = firstDay.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))  // 22:30
         return "\(day) · \(time)"
     } else {
         return "Invite Time Expired"
     }
 }

 var clockIcon: some View {
     Image("MiniClockIcon")
         .scaleEffect(1.1, anchor: .bottom)
         .frame(width: 20, alignment: .leading)
 }

 
 Old logic for popup
 
 private var eventTimeLine: some View {
     TimeCustomMenu {
         Text("Show Time Here")
             .onTapGesture {timeMenuDismiss()}
     } label: {
         HStack(spacing: 10) {
             clockIcon
             HStack(spacing: 12) {
                 Text(formattedDay)
                 DropDownButton(isOpen: false, isAccept: true)
             }
         }
     }
 }

 
 */
