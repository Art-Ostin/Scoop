//
//  ExpiredInvites .swift
//  Scoop
//
//  Created by Art Ostin on 25/08/2026.
//

import SwiftUI

//Sent invites whose every time has passed: a heading that opens a card of rows, each row opening in place
struct ExpiredInvites: View {

    //Injected
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

                HistoryChevron(isExpanded: showsExpired)
                    .padding(.trailing, Spacing.md) //In the rows' chevron column: the card insets its rows by the same
                    .accessibilityHidden(true) //The button's value says whether it is open
            }
            .expandHitArea(Spacing.sm) //One text line is a thin target, and the Spacer's gap carries no shape of its own
        }
        .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
        .accessibilityValue(showsExpired ? "Expanded" : "Collapsed")
    }

    private var expiredDetail: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) { //Note → its card
            Text("Invites where all your invited times have expired. They can still respond by proposing a new time")
                .customSubtitle(lineSpacing: Spacing.xxs, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            expiredCard
        }
        .padding(.top, Spacing.sm) //Heading → note, rolled away with the rest
    }

    private var expiredCard: some View {
        InviteListCard(rowCount: expiredInvites.count) {
            ForEach(expiredInvites) { event in
                ExpiredEventCard(
                    event: event,
                    showsDivider: event.id != expiredInvites.last?.id,
                    isExpanded: expandedInvite == event.id,
                    onToggle: { toggle(event.id) }
                )
            }
        }
    }
}
