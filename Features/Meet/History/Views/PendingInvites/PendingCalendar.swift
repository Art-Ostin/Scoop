//
//  PendingCalendar.swift
//  Scoop
//
//  Created by Art Ostin on 25/08/2026.
//

import SwiftUI

//Every day one of your live invites still proposes, in one card. One row is one day, whoever it
//holds — an invite offering three days puts its face on all three rows. Tapping a face opens
//that invite's card at the top of the page.
struct PendingCalendar: View {

    //Injected
    let days: [InviteDay]
    let expandedInvite: String? //Held by the container, so the face and the card above it name the same invite
    let onTapInvite: (String) -> Void

    //Local view state
    @State private var openDays: Set<Date> = [] //Days showing every face — the +N chip's own reveal, like HeaderRow's note

    //The glass face: the Messages profile button's own 32pt image, ringed by glass to 42 —
    //two under the toolbar platter's 44pt floor, so it reads as the same control one size down
    private static let glassAvatar: CGFloat = 32
    private static let glassRing: CGFloat = 5 //Geometry: 32 + 5 + 5 = the 42pt circle

    //The open invite's face wears an accent ring on the rim of its lens, leaving the glass clean
    private static let selectedStroke: CGFloat = 1.5 //Geometry: centred on the 42pt rim, so 0.75pt either side

    private static let facesPerLine = 4 //Four 42pt lenses is all one line holds beside its day

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InviteListCard(rowCount: days.count) {
                ForEach(days) { day in
                    dayRow(day, showsDivider: day.id != days.last?.id)
                }
            }

            if hasSharedDay {
                Text("As soon as one person accepts, your invite to the others for that day expires")
                    .infoText()
                    .padding(.top, Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    //The rule a shared day raises — said only while some day actually holds two invites
    private var hasSharedDay: Bool {
        days.contains { $0.invites.count > 1 }
    }
}

//The row: its day on the left, the faces you invited on it on the right
extension PendingCalendar {

    private func dayRow(_ day: InviteDay, showsDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Text(FormatEvent.monthDay(day.day))
                    .font(.body(16, .bold))
                    .foregroundStyle(Color.textPrimary)
                    .oneLineLimitAndShrink() //"Tomorrow" beside a full four-cell line leaves 75pt on a 375pt device — shrink, never truncate
                    .frame(height: Self.glassAvatar + 2 * Self.glassRing) //Geometry: centred on the pile's first line, wherever the pile wraps

                Spacer(minLength: 0) //The HStack's own two seams already hold 32pt of air; a full face line needs the rest

                glassFacePile(day)
            }
            .padding(.vertical, Spacing.xs) //The row's own half of the gap; the rule below adds the rest

            if showsDivider {
                LightDivider()
                    .padding(.vertical, Spacing.xs) //With the row's own, 16 above and 16 below the rule
            }
        }
    }
}

//The same row of faces, each wearing the glass the Messages profile button gets from the
//toolbar platter. No white circleStroke: these faces don't overlap, so there is nothing for a
//ring to cut them out of — the only ring here is the accent one that marks the open invite.
extension PendingCalendar {

    //A face per invite, and a +N chip once the day outgrows one line: collapsed, the chip takes
    //the fourth slot and counts what it hides; open, every face shows, wrapped four to a line,
    //with the chip closing the run to fold it back.
    private func glassFacePile(_ day: InviteDay) -> some View {
        let cells = cells(for: day)
        let lines = stride(from: 0, to: cells.count, by: Self.facesPerLine).map {
            Array(cells[$0..<min($0 + Self.facesPerLine, cells.count)])
        }

        return VStack(alignment: .trailing, spacing: Spacing.sm) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: Spacing.sm) {
                    ForEach(line) { cell in
                        switch cell {
                        case .face(let invite): glassFace(invite)
                        case .toggle(let hidden): overflowChip(day, hidden: hidden)
                        }
                    }
                }
            }
        }
    }

    private enum FaceCell: Identifiable {
        case face(EventProfile)
        case toggle(hidden: Int) //0 once the day is open: the chip then folds rather than counts

        var id: String {
            switch self {
            case .face(let invite): invite.id
            case .toggle: "toggle" //Unique within its line's ForEach; the chip's slot moves between lines on fold/unfold, so it crossfades rather than travels
            }
        }
    }

    private func cells(for day: InviteDay) -> [FaceCell] {
        guard day.invites.count > Self.facesPerLine else { return day.invites.map(FaceCell.face) }

        if openDays.contains(day.id) {
            return day.invites.map(FaceCell.face) + [.toggle(hidden: 0)]
        }
        let shown = Self.facesPerLine - 1 //The chip takes the fourth slot
        return day.invites.prefix(shown).map(FaceCell.face) + [.toggle(hidden: day.invites.count - shown)]
    }

    private func glassFace(_ invite: EventProfile) -> some View {
        //An invite proposing three days wears the ring on all three rows — it reads as
        //"these are the days that one invite offered", which is what the card above is showing
        let isSelected = expandedInvite == invite.id

        return Button { onTapInvite(invite.id) } label: {
            SmallImage(image: invite.image ?? UIImage(), size: Self.glassAvatar, isCircle: true)
                .padding(Self.glassRing)
                .glassEffectIfAvailable(shape: Circle()) //Not scoopGlassSurface: its interactive lens clamps the hit area
                .circleStroke(lineWidth: Self.selectedStroke, color: isSelected ? .accent : .clear)
                .contentShape(Circle()) //The 42pt circle is the target, not the padded square
                .animation(.toggle, value: isSelected) //Selection, not the drawer's .expand the tap also runs
        }
        .shrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
        .accessibilityLabel(invite.profile.name)
    }

    private func overflowChip(_ day: InviteDay, hidden: Int) -> some View {
        let isOpen = openDays.contains(day.id)

        return Button { toggleOverflow(day.id) } label: {
            Group {
                if isOpen {
                    Image(systemName: "chevron.up")
                        .font(.icon(13, .semibold))
                } else {
                    Text("+\(hidden)")
                        .font(.body(14, .bold))
                }
            }
            .foregroundStyle(Color.textSecondary)
            .frame(width: Self.glassAvatar, height: Self.glassAvatar)
            .padding(Self.glassRing)
            .glassEffectIfAvailable(shape: Circle()) //Not scoopGlassSurface: its interactive lens clamps the hit area
            .contentShape(Circle()) //The 42pt circle is the target, not the padded square
        }
        .shrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
        .accessibilityLabel(isOpen ? "Show fewer" : "\(hidden) more invites")
    }

    private func toggleOverflow(_ dayID: Date) {
        withAnimation(.expand) {
            if openDays.contains(dayID) { openDays.remove(dayID) } else { openDays.insert(dayID) }
        }
    }
}
