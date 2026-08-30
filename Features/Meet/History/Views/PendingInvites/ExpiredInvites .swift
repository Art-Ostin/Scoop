//
//  ExpiredInvites .swift
//  Scoop
//
//  Created by Art Ostin on 25/08/2026.
//

import SwiftUI

struct ExpiredInvites: View {
    
    let expiredInvites: [EventProfile]
    let expandedInvite: String? //Its own id, separate from the pending selection — opening a row here can't strand the card above
    
    @Binding var showsExpired: Bool
        
    let toggle: (String) -> Void

    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            expiredHeader
            
            expiredDetail
                .drawer(isOpen: showsExpired)
        }
    }
}

extension ExpiredInvites {
    
    //The whole heading is the control, its chevron turning down as the section opens
    private var expiredHeader: some View {
        Button {
            withAnimation(.unfold) { showsExpired.toggle() } //Not .expand: six invites is a tall reveal
        } label: {
            HStack {
                Text("Unanswered Invites")
                    .font(.headline)              // SF Pro 17pt semibold
                    .foregroundStyle(.secondary)
                
                Spacer()
                expiredChevron
            }
            .expandHitArea(Spacing.sm) //One text line is a thin target, and the Spacer's gap carries no shape of its own
        }
        .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
    }
    
    private var expiredDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Invites where all your invited times have expired. They can still respond by proposing a new time.")
                .infoText()
                .padding(.top, Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !expiredInvites.isEmpty {
                expiredCard
                    .padding(.top, Spacing.sm) //Note → its card
            }
        }
        .padding(.top, Spacing.hairline) //The nudge the heading kept above its note
    }
    
    private var expiredCard: some View {
        InviteListCard(rowCount: expiredInvites.count) {
            ForEach(expiredInvites) { event in
                ExpiredEventCard(
                    event: event,
                    showsDivider: event.id != expiredInvites.last?.id,
                    isExpanded: expandedInvite == event.id,
                    onToggle: { toggle(event.id)}
                )
            }
        }
    }
    
    private var expiredChevron: some View {
        Image(systemName: "chevron.right")
            .font(.body(15, .bold))
            .foregroundStyle(Color.textSecondary)
            .rotationEffect(.degrees(showsExpired ? 90 : 0)) //Right → down, as the rows' own chevrons
            .animation(.toggle, value: showsExpired)
            .padding(.trailing, 6)
    }
}
