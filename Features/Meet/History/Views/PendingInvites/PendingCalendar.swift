//
//  PendingCalendar.swift
//  Scoop
//
//  Created by Art Ostin on 29/08/2026.
//

import SwiftUI

private typealias Face = (invite: EventProfile, isFirst: Bool)

struct PendingCalendar: View {

    //Injected
    let inviteDays: [InviteDay]

    //Local view state
    @State private var openDays: Set<Date> = [] //Days showing every face — the +N chip's own reveal

    //TODO: the composer proposes across 11 days (DayPicker.dayCount) — share one horizon constant when the data wiring lands
    private static let dayCount = 10

    //The glass face: image + thin glass edge = the 44pt circle the toolbar platter set.
    //An echo (the same invite's other proposed days) is the same lens at 0.7 scale — size is
    //the ONLY differentiator (dimming already means lapsed elsewhere), so the gap stays wide.
    private static let faceSize: CGFloat = 40
    private static let echoFaceSize: CGFloat = 28
    private static let glassRing: CGFloat = 2 //Geometry: 40 + 2 + 2 = the 44pt circle
    private static let lensFrame: CGFloat = 44 //The primary's footprint, and EVERY lens' touch circle
    private static let echoLens = echoFaceSize + 2 * glassRing //The echo's real 32pt footprint — laid out true-size so echo-only rows sit low and the rail stays straight
    private static let echoHitInset = (lensFrame - echoLens) / 2 //Geometry: pads the echo's touch circle back to the 44pt contract

    private static let facesPerLine = 4 //Four 44pt lenses is all one line holds beside its day

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HeaderRow(title: "Next 10 Days", note: acceptanceNote)

            let faces = ledger //One pass, read ten times — not rebuilt per row

            VStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    dayRow(day: day, faces: faces[day] ?? [], showsDivider: day != days.last)
                }
            }
            .padding(.horizontal, Spacing.md) //Rows own all vertical rhythm — the card adds none
            .frame(maxWidth: .infinity)
            .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
        }
    }
}

//The rows: a bold day holding lenses, or a slim quiet line for a free day
extension PendingCalendar {

    private func dayRow(day: Date, faces: [Face], showsDivider: Bool) -> some View {
        VStack(spacing: 0) {
            if faces.isEmpty { noEventDay(day: day) }
            else { eventDay(day: day, faces: faces) }

            if showsDivider {
                VeryLightDivider()
            } //Rows carry their half of every seam; the rule carries none
        }
    }

    private func noEventDay(day: Date) -> some View {
        Text(FormatEvent.shortDayAndTime(day, withHour: false, withToday: true))
            .font(.body(14, .regular))
            .foregroundStyle(Color.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.xs) //The slim row's own half of the gap
    }

    private func eventDay(day: Date, faces: [Face]) -> some View {
        let hasPrimary = faces.contains { $0.isFirst }

        //.top: a wrapped pile grows downward while the day stays on its first line
        return HStack(alignment: .top, spacing: Spacing.md) {
            dayTitle(day: day, lineHeight: hasPrimary ? Self.lensFrame : Self.echoLens)

            Spacer(minLength: 0)

            facePile(day: day, faces: faces)
        }
        //An echo-only day is the middle tier — possible, not planned — so its row sits
        //between the full day and the slim free day
        .padding(.vertical, hasPrimary ? Spacing.md : Spacing.sm)
    }

    private func dayTitle(day: Date, lineHeight: CGFloat) -> some View {
        Text(FormatEvent.shortDayAndTime(day, withHour: false, withToday: true))
            .font(.body(16, .bold))
            .foregroundStyle(Color.textPrimary)
            .oneLineLimitAndShrink() //"Tomorrow" beside a full four-lens line — shrink, never truncate
            .frame(height: lineHeight) //Geometry: centred on the pile's first line, wherever the pile wraps
    }

    private var days: [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        return (0..<Self.dayCount).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    //The deadline always, and the rule a shared day raises only while some day actually holds
    //two invites — the case where one acceptance decides the others.
    private var acceptanceNote: String {
        let deadline = "They have until \(Int(ProposedTimes.acceptanceLead / 3600)) hours before the invite to accept"
        guard inviteDays.contains(where: { $0.invites.count > 1 }) else { return deadline }
        return deadline + "\n\nAs soon as one person accepts, your invite to the others for that day expires"
    }
}

//The face pile: echoes step in from the left, primaries anchor the rail, and a day over one
//line collapses behind a +N chip in the leading slot so the rail never loses its primaries.
extension PendingCalendar {

    private enum FaceCell: Identifiable {
        case face(Face)
        case toggle(hidden: Int) //0 once the day is open: the chip then folds rather than counts

        var id: String {
            switch self {
            case .face(let face): face.invite.id
            case .toggle: "toggle" //Unique within its row's ForEach
            }
        }
    }

    private func facePile(day: Date, faces: [Face]) -> some View {
        let cells = cells(day: day, faces: faces)
        let lines = stride(from: 0, to: cells.count, by: Self.facesPerLine).map {
            Array(cells[$0..<min($0 + Self.facesPerLine, cells.count)])
        }

        return VStack(alignment: .trailing, spacing: Spacing.sm) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: Spacing.sm) {
                    ForEach(line) { cell in
                        switch cell {
                        case .face(let face): lens(face)
                        case .toggle(let hidden): overflowChip(day, hidden: hidden)
                        }
                    }
                }
            }
        }
    }

    private func cells(day: Date, faces: [Face]) -> [FaceCell] {
        guard faces.count > Self.facesPerLine else { return faces.map(FaceCell.face) }

        if openDays.contains(day) {
            return [.toggle(hidden: 0)] + faces.map(FaceCell.face)
        }
        let shown = Self.facesPerLine - 1 //The chip takes the leading slot
        //suffix, not prefix: faces run echoes-then-firsts, so the rail keeps its primaries
        return [.toggle(hidden: faces.count - shown)] + faces.suffix(shown).map(FaceCell.face)
    }

    private var ledger: [Date: [Face]] {
        var seen: Set<String> = []
        var out: [Date: [Face]] = [:]

        for row in inviteDays.sorted(by: { $0.day < $1.day }) {
            var firsts: [Face] = []
            var echoes: [Face] = []

            for invite in row.invites {
                if seen.insert(invite.id).inserted {
                    firsts.append((invite, true))
                } else {
                    echoes.append((invite, false))
                }
            }
            out[row.day] = echoes + firsts //Firsts last: the trailing edge is the row's anchor
        }
        return out
    }

    private func lens(_ face: Face) -> some View {
        Button {
            //TODO: present the invite popup when the tap-to-open wiring lands
        } label: {
            SmallImage(image: face.invite.image ?? UIImage(), size: face.isFirst ? Self.faceSize : Self.echoFaceSize, isCircle: true)
                .padding(Self.glassRing)
                .glassEffectIfAvailable(shape: Circle())
                .clipShape(Circle()) //Clips the glass's own cast shadow — the no-shadow floor; eleven glowing circles read as noise
                //The echo lays out at its real 32pt but keeps the 44pt touch circle: pad out,
                //take the shape, pad back — the reach stays without growing the row
                .padding(face.isFirst ? 0 : Self.echoHitInset)
                .contentShape(Circle()) //PressButtonStyle sets none — without it the padding ring misses
                .padding(face.isFirst ? 0 : -Self.echoHitInset)
        }
        .shrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
        .accessibilityLabel(face.isFirst ? face.invite.profile.name : "\(face.invite.profile.name) — alternative day")
    }

    private func overflowChip(_ day: Date, hidden: Int) -> some View {
        let isOpen = openDays.contains(day)

        return Button { toggleOverflow(day) } label: {
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
            .frame(width: Self.faceSize, height: Self.faceSize)
            .padding(Self.glassRing)
            .glassEffectIfAvailable(shape: Circle())
            .clipShape(Circle()) //Clips the glass's own cast shadow — the no-shadow floor, matching the lenses
            .contentShape(Circle())
        }
        .shrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
        .accessibilityLabel(isOpen ? "Show fewer" : "\(hidden) more invites")
    }

    private func toggleOverflow(_ day: Date) {
        withAnimation(.expand) {
            if openDays.contains(day) { openDays.remove(day) } else { openDays.insert(day) }
        }
    }
}
