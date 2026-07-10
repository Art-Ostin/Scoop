//
//  InviteCardEventInfo.swift
//  Scoop
//
//  Created by Art Ostin on 22/06/2026.
//

import SwiftUI

struct InviteCardInfo: View {
    
    //Injected
    @Environment(\.timeCustomMenuDismiss) private var timeMenuDismiss
    @Binding var draft: RespondDraft
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
                .scaleEffect(1.2, anchor: .center)
                .frame(width: 20, alignment: .leading)

            Text("Barbossa Montreal") //eventProfile.event.location.name ?? ""
                .foregroundStyle(Color.successGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 19)
        }
    }
    
    private var eventTimeLine: some View {
        RespondTimeRow(draft: $draft, rowHasIcon: true)
    }
        
    private var infoButton: some View {
        SmallInfoIcon(size: 12, colour: Color.textPlaceholder)
            .padding()
            .padding(.trailing, 8)
    }
    
    private var inviteButton: some View {
        InviteButton(isInviting: false, isInviteCard: true) {
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
            .background(Color.appCanvas, in: .rect(cornerRadius: CornerRadius.concentric(in: CornerRadius.image, inset: 12), style: .continuous))
    }
}
