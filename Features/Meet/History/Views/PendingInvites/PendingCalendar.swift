//
//  PendingCalendar.swift
//  Scoop
//
//  Created by Art Ostin on 25/08/2026.
//

import SwiftUI

//Every day one of your live invites still proposes, in one card. One row is one day, whoever it
//holds — an invite offering three days puts its face on all three rows. Tapping a face opens
//that invite's card in the list above.
struct PendingCalendar: View {

    //Injected
    let days: [InviteDay]
    let onTapInvite: (String) -> Void

    private static let avatar: CGFloat = 38 //The Events photoOverlap face

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderRow(title: "Days", note: message)
                .padding(.bottom, Spacing.sm)

            InviteListCard(rowCount: days.count) {
                ForEach(days) { day in
                    dayRow(day, showsDivider: day.id != days.last?.id)
                }
            }
        }
    }

    private var message: String { // TODO: final copy
        "Every day you're still waiting on an answer for"
    }
}

//The row: its day on the left, the faces you invited on it on the right
extension PendingCalendar {

    private func dayRow(_ day: InviteDay, showsDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.md) {
                Text(FormatEvent.monthDay(day.day))
                    .font(.body(16, .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: Spacing.xs)

                facePile(day)
            }
            .padding(.vertical, Spacing.xs) //The row's own half of the gap; the rule below adds the rest

            if showsDivider {
                LightDivider()
                    .padding(.vertical, Spacing.xs) //With the row's own, 16 above and 16 below the rule
            }
        }
    }

    private func facePile(_ day: InviteDay) -> some View {
        HStack(spacing: 18 - Self.avatar) { //Geometry: each face advances 18pt — the Events photoOverlap pitch, laid flat
            ForEach(day.invites.prefix(4)) { invite in //Four faces is all the row can hold beside its day
                face(invite)
            }
        }
    }

    private func face(_ invite: EventProfile) -> some View {
        Button { onTapInvite(invite.id) } label: {
            SmallImage(image: invite.image ?? UIImage(), size: Self.avatar, isCircle: true)
                .circleStroke(lineWidth: 1.5, color: .white) //The card behind, cutting each face out of the one under it
        }
        .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
        .accessibilityLabel(invite.profile.name)
    }
}
