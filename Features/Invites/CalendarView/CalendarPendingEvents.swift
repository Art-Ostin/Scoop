//
//  CalendarPendingEvents.swift
//  Scoop
//
//  Created by Art Ostin on 15/09/2026.
//

import SwiftUI

//One invite's face on one day. The first day an invite can still be accepted on carries its
//primary lens; every later day it proposes carries an echo of that same lens.
private struct DayFace: Identifiable {
    let invite: EventProfile
    let isFirst: Bool

    var id: String { invite.id }
}

//A slot in a day's pile: a face, or the +N chip that folds the faces past one line
private enum FaceCell: Identifiable {
    case face(DayFace)
    case toggle(hidden: Int) //0 once the day is open: the chip then folds rather than counts

    var id: String {
        switch self {
        case .face(let face): face.id
        case .toggle: "toggle" //Unique within its row's ForEach
        }
    }
}

struct CalendarPendingEvents: View {

    //Injected
    let invites: [InviteDay]
    let acceptedEvents: [EventProfile]
    let onOpen: (EventProfile, Date) -> Void //Runs on tap, just before the card opens
    let card: (EventProfile) -> AnyView //.eventZoom wraps its card in AnyView anyway
    let meetingCard: (EventProfile) -> AnyView
    var facesPerLine = 3 //Faces on a line before the pile wraps
    var collapsesOverflow = false //A day over one line folds behind a +N chip in its leading slot, rather than wrapping
    var faceSpacing = Spacing.sm //Between faces, across and down: a narrow column buys the date its width back here

    //Local view state
    @State private var selectedLensID: String? //Which avatar's card is open
    @State private var openDays: Set<Date> = [] //Days showing every face — the +N chip's own reveal

    private static let rowHeight: CGFloat = 72
    private static let freeRowHeight: CGFloat = 40

    var body: some View {
        let booked = meetings
        let faces = ledger(skipping: Set(booked.keys)) //One pass, read once per row — not rebuilt per face
        let rows = days

        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element) { index, day in
                dayRow(day: day,
                       faces: faces[day] ?? [],
                       meeting: booked[day],
                       showsDivider: index + 1 < rows.count)
            }
        }
    }
}

//Views
extension CalendarPendingEvents {

    //A hairline under every row but the last: the day and its faces sit a column apart, and the
    //rule is what says they are one row
    private func dayRow(day: Date, faces: [DayFace], meeting: EventProfile?, showsDivider: Bool) -> some View {
        let isActive = !faces.isEmpty || meeting != nil

        return VStack(spacing: 0) {
            //The label takes the slack, not a Spacer: a stack spaces both sides of a Spacer, which
            //would charge the date the gap twice
            HStack(alignment: .top, spacing: Spacing.sm) {
                dayLabel(for: day, isActive: isActive)
                    .frame(height: isActive ? Self.rowHeight : Self.freeRowHeight) //Centred on the row's first line, however far the pile wraps
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let meeting {
                    meetingButton(meeting)
                        .id(meeting.id) //A different meeting taking this day remounts the lens: its open card fades out, never flies home onto the new face
                        .frame(height: Self.rowHeight)
                } else {
                    let lines = lines(of: cells(day: day, faces: faces))
                    facePile(lines, day: day)
                        .frame(height: isActive ? Self.rowHeight * CGFloat(lines.count) : Self.freeRowHeight)
                }
            }

            if showsDivider { VeryLightDivider() }
        }
        .accessibilityElement(children: .contain) //The day names the faces beside it; each face stays its own target
    }

    //One size in both states, so the column's type never steps — a free day is lighter, not smaller
    private func dayLabel(for day: Date, isActive: Bool) -> some View {
        Text(FormatEvent.monthDay(day))
            .font(.body(16, isActive ? .bold : .regular))
            .foregroundStyle(isActive ? Color.textPrimary : Color.textTertiary)
            .oneLineLimitAndShrink() //"Tomorrow" beside a full line of faces — shrink, never truncate
    }

    //Trailing-aligned, and the ledger leads with echoes, so the last face of the last line is
    //always a primary — the rail the rows hang off
    private func facePile(_ lines: [[FaceCell]], day: Date) -> some View {
        VStack(alignment: .trailing, spacing: faceSpacing) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: faceSpacing) {
                    ForEach(line) { cell in
                        switch cell {
                        case .face(let face): avatarButton(face: face, day: day)
                        case .toggle(let hidden): overflowChip(day, hidden: hidden)
                        }
                    }
                }
            }
        }
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
            .frame(width: AvatarFace.faceSize, height: AvatarFace.faceSize)
            .padding(AvatarFace.ring)
            .glassEffectIfAvailable(shape: Circle())
            .clipShape(Circle()) //Clips the glass's own cast shadow — the no-shadow floor, matching the lenses
            .contentShape(Circle())
        }
        .shrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
        .accessibilityLabel(isOpen ? "Show fewer" : "\(hidden) more invites")
    }

    private func avatarButton(face: DayFace, day: Date) -> some View {
        //One invite can be on up to 3 days, so the ID includes the day, or all 3 avatars would open at once
        let lensID = "\(face.invite.id)#\(Int(day.timeIntervalSinceReferenceDate))"
        let name = face.invite.profile.name

        return Button {
            onOpen(face.invite, day) //First, so the card opens on the tapped day
            selectedLensID = lensID
        } label: {
            AvatarFace(image: face.invite.image, isFirst: face.isFirst, gap: faceSpacing)
        }
        .shrinkButton()
        .instantPressDelivery()
        .accessibilityLabel(face.isFirst ? name : "\(name) — alternative day") //The same name sits on up to 3 rows
        .eventZoom(isPresented: isPresented(lensID)) {
            card(face.invite)
        }
    }

    private func meetingButton(_ meeting: EventProfile) -> some View {
        Button {
            selectedLensID = meeting.id
        } label: {
            AvatarFace(image: meeting.image, isFirst: true, tint: .accent)
        }
        .shrinkButton()
        .instantPressDelivery()
        .accessibilityLabel("Meeting \(meeting.profile.name)")
        .eventZoom(isPresented: isPresented(meeting.id)) {
            meetingCard(meeting)
        }
    }

    //Clears only if it's still this avatar's, so a card that finishes closing can't close a newer one
    private func isPresented(_ lensID: String) -> Binding<Bool> {
        Binding {
            selectedLensID == lensID
        } set: { presented in
            if presented { selectedLensID = lensID }
            else if selectedLensID == lensID { selectedLensID = nil }
        }
    }
}

//Helper Functions
extension CalendarPendingEvents {

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let furthest = (invites.map(\.day) + Array(meetings.keys)).max() ?? today
        let span = max(ProposedTimes.horizonDays, (cal.dateComponents([.day], from: today, to: furthest).day ?? 0) + 1)

        return (0..<span).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    //One accepted event per day. Two on one day keep the earlier time (then the lower id), so the
    //row never swaps between them as the events list reorders
    private var meetings: [Date: EventProfile] {
        let dated = acceptedEvents.compactMap { event in event.event.acceptedTime.map { (time: $0, event: event) } }
        return Dictionary(grouping: dated) { Calendar.current.startOfDay(for: $0.time) }
            .compactMapValues { sameDay in sameDay.min { ($0.time, $0.event.id) < ($1.time, $1.event.id) }?.event }
    }

    private func ledger(skipping booked: Set<Date>) -> [Date: [DayFace]] {
        var seen: Set<String> = []
        var out: [Date: [DayFace]] = [:]

        for row in invites.sorted(by: { $0.day < $1.day }) where !booked.contains(row.day) {
            var firsts: [DayFace] = []
            var echoes: [DayFace] = []

            for invite in row.invites {
                if seen.insert(invite.id).inserted {
                    firsts.append(DayFace(invite: invite, isFirst: true))
                } else {
                    echoes.append(DayFace(invite: invite, isFirst: false))
                }
            }
            out[row.day] = echoes + firsts
        }
        return out
    }

    private func cells(day: Date, faces: [DayFace]) -> [FaceCell] {
        guard collapsesOverflow, faces.count > facesPerLine else { return faces.map(FaceCell.face) }

        if openDays.contains(day) {
            return [.toggle(hidden: 0)] + faces.map(FaceCell.face)
        }
        let shown = facesPerLine - 1 //The chip takes the leading slot
        //suffix, not prefix: faces run echoes-then-firsts, so the rail keeps its primaries
        return [.toggle(hidden: faces.count - shown)] + faces.suffix(shown).map(FaceCell.face)
    }

    private func lines(of cells: [FaceCell]) -> [[FaceCell]] {
        stride(from: 0, to: cells.count, by: facesPerLine).map {
            Array(cells[$0..<min($0 + facesPerLine, cells.count)])
        }
    }

    private func toggleOverflow(_ day: Date) {
        withAnimation(.expand) {
            if openDays.contains(day) { openDays.remove(day) } else { openDays.insert(day) }
        }
    }
}

//The avatar's look: its own view, so it can read the zoom state .eventZoom puts above it
struct AvatarFace: View {
    //Injected
    let image: UIImage?
    let isFirst: Bool
    var tint: Color? = nil
    var gap = Spacing.sm //To its neighbours on a line: the echo's tap circle may grow halfway across it

    @Environment(EventZoomAnchor.self) private var anchor: EventZoomAnchor?

    //Geometry: the two tiers. The primary wears the heavier rim and the echo a lighter one, so the
    //echo stays legible as a face rather than reading as all rim.
    static let faceSize: CGFloat = 44
    static let echoFaceSize: CGFloat = 36
    static let ring: CGFloat = 5
    static let echoRing: CGFloat = 4
    static let lensFrame = faceSize + 2 * ring        //Geometry: the primary's 54pt footprint, and a row's tallest content
    static let echoLens = echoFaceSize + 2 * echoRing //Geometry: the echo's true 44pt footprint

    //Geometry: pads the echo's touch circle out toward lensFrame, but never past half the gap to
    //its neighbour — two echoes would otherwise trade taps wherever their circles overlap
    private var echoHitInset: CGFloat { min((Self.lensFrame - Self.echoLens) / 2, gap / 2) }

    var body: some View {
        let rim = isFirst ? Self.ring : Self.echoRing
        let hitInset = isFirst ? 0 : echoHitInset

        SmallImage(image: image ?? UIImage(), size: isFirst ? Self.faceSize : Self.echoFaceSize, isCircle: true)
            .background(Circle().fill(Color.fillGray)) //A face still loading is a grey disc, not an empty ring
            .eventZoomSource(image ?? UIImage(), shape: .circle(ring: rim, tint: tint)) //The photo that grows into the card; the close lands it wearing this ring's tint
            .padding(rim) //Geometry: the glass ring's width
            .lightShadow()
            .containerGlassEffect(tint: tint, clipped: true, shape: Circle())
            .opacity(anchor?.returning == true ? 0 : 1) //The closing flight draws its own ring, tint and all, so hide this one
            .padding(hitInset) //Geometry: grows the echo's tap circle toward the primary's
            .contentShape(Circle()) //PressButtonStyle sets none — without it the padding ring misses
            .padding(-hitInset) //Geometry: gives the space back, so the echo lays out at its true size
    }
}
