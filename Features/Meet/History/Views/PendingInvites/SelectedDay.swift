//
//  SelectedDay.swift
//  Scoop
//
//  Created by Art Ostin on 27/08/2026.
//

import SwiftUI

struct SelectedDay: View {

    //Injected
    let event: EventProfile

    private static let avatar: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InviteListCard(rowCount: 1, tightensSingleRow: false) { //One expanded row, so it keeps the full inset
                selectedDay
            }
        }
    }
}

extension SelectedDay {

    private var selectedDay: some View {
        HStack(alignment: .top, spacing: Spacing.md) {

            if let image = event.image {
                SmallImage(image: image, size: Self.avatar, isCircle: true)
            }

            VStack(alignment: .leading, spacing: 0) { //Each detail row carries its own top step, as the card's does
                HStack {
                    HistoryName(name: event.profile.name, size: 19)
                    Spacer()
                    type
                }
                timeRow
                HistoryPlaceRow(location: event.event.location)
                HistoryMessageSection(message: event.event.message)
            }
        }
        .padding(.vertical, Spacing.xs) //The row's own half of the card's inset, top and bottom
    }

    //One line with the shared hour at its tail when every day strikes the same time; one line
    //per day, each wearing its own hour, when they differ — the hour is the information then.
    @ViewBuilder private var timeRow: some View {
        let times = event.event.proposedTimes

        if times.sharesOneHour {
            times.invitedDayPieces()
                .map { Text($0.text).foregroundStyle($0.lapsed ? Color.textTertiary : .textSecondary) }
                .reduce(Text(""), +)
                .font(.body(15, .regular))
                .oneLineLimitAndShrink() //Three long days shrink as one line, as the expired row does
                .padding(.top, Spacing.xs) //Type → times: the same step the place row keeps below
        } else {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                ForEach(times.invitedDayHourPieces(), id: \.text) { piece in
                    Text(piece.text)
                        .foregroundStyle(piece.lapsed ? Color.textTertiary : .textSecondary)
                }
            }
            .font(.body(15, .regular))
            .padding(.top, Spacing.xs) //Type → times: the same step the place row keeps below
        }
    }

    private var type: some View {
        let type = event.event.type

        return HStack(alignment: .center, spacing: Spacing.xxs) {
            Text(type.emoji)

            Text(type.longTitle)
        }
        .font(.body(13, .medium))
        .foregroundStyle(Color.textPrimary)
        .frame(height: 24)
        .padding(.trailing, Spacing.xs)
        .padding(.leading, 6) //Geometry: the emoji glyph carries its own leading air, so 2pt less than the trailing inset
        .offset(y: -1) //Geometry: optical centre against the 19pt name beside it
    }
}
