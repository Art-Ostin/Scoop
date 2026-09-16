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
    let upcomingEvents: [EventProfile] //Accepted events: one takes its whole day, and no pending face shares that day
    private let card: (EventProfile) -> AnyView //What a lens opens: the screen that owns the calendar decides
    private let meetingCard: (EventProfile) -> AnyView //What a meeting's lens opens
    private let onOpen: (EventProfile, Date) -> Void //A lens tapped on its day, just before its card opens: the owner can pose the card for that day


    //Local view state
    @State private var openDays: Set<Date> = [] //Days showing every face — the +N chip's own reveal
    @State private var selectedLensID: String? //Which lens is up — either lens of an invite opens the same card, grown out of the one tapped

    //Generic init, erased once: .eventZoom wraps its card in AnyView anyway, and a generic type would outlaw the static layout constants below
    init<Card: View, MeetingCard: View>(inviteDays: [InviteDay], upcomingEvents: [EventProfile],
                                        onOpen: @escaping (EventProfile, Date) -> Void = { _, _ in },
                                        @ViewBuilder card: @escaping (EventProfile) -> Card,
                                        @ViewBuilder meetingCard: @escaping (EventProfile) -> MeetingCard) {
        self.inviteDays = inviteDays
        self.upcomingEvents = upcomingEvents
        self.onOpen = onOpen
        self.card = { AnyView(card($0)) }
        self.meetingCard = { AnyView(meetingCard($0)) }
    }

    private static let faceSize: CGFloat = 42
    private static let echoFaceSize: CGFloat = 28
    //The primary wears a deliberately heavy edge and the echo a lighter one — 5pt of rim on a
    //28pt face would read as all rim, and the echo has to stay legible as a face
    private static let glassRing: CGFloat = 5
    private static let echoGlassRing: CGFloat = 3
    private static let lensFrame = faceSize + 2 * glassRing //Geometry: the primary's 52pt footprint, and EVERY lens' touch circle
    private static let echoLens = echoFaceSize + 2 * echoGlassRing //The echo's real 34pt footprint — laid out true-size so echo-only rows sit low and the rail stays straight
    //Geometry: pads the echo's touch circle out toward lensFrame, but never past half the gap
    //to its neighbour — at Spacing.sm apart that lands on the 44pt minimum, and two echoes
    //would otherwise trade taps wherever their circles overlap
    private static let echoHitInset = min((lensFrame - echoLens) / 2, Spacing.sm / 2)

    //Each tier's row height is the fixed quantity and its padding is the remainder, split top
    //and bottom — grow either lens and its row holds, until that padding runs out.
    private static let rowHeight: CGFloat = 76 //Geometry: the primary row as it settled — a 44pt lens + 2 × Spacing.md
    private static let echoRowHeight: CGFloat = 56 //Geometry: the echo row as it settled — a 32pt lens + 2 × Spacing.sm
    private static let primaryPad = (rowHeight - lensFrame) / 2 //Geometry: 12 at a 52pt lens — gives back exactly what the lens took
    private static let echoPad = (echoRowHeight - echoLens) / 2 //Geometry: 11 at a 34pt lens
    private static let freeRowHeight: CGFloat = 40 //Geometry: the same as the Calendar View's free rows (CalendarPendingEvents)

    //Four lenses is all one line holds beside its day — and at 52pt it is over budget: a long
    //label ("Wed Sep 30") renders at ~77% on a 393pt phone, and hits the 0.7 shrink floor and
    //truncates below that. Three per line is the fix if it shows.
    private static let facesPerLine = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
//            HeaderRow(title: "Active", note: acceptanceNote)

            let booked = meetings
            let faces = ledger(skipping: Set(booked.keys)) //One pass, read once per row — not rebuilt per row
            let rows = days(booked: booked)
            //A meeting day is busy, though the ledger gives it no faces
            let isFree = { (day: Date) in (faces[day] ?? []).isEmpty && booked[day] == nil }

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element) { index, day in
                    let hasNext = index + 1 < rows.count
                    dayRow(day: day,
                           faces: faces[day] ?? [],
                           meeting: booked[day],
                           showsDivider: hasNext && !(isFree(day) && isFree(rows[index + 1])))
                }
            }
            .padding(.horizontal, 0) //Rows own all vertical rhythm — the card adds none
            .frame(maxWidth: .infinity)
            .background(Color.appCanvas, in: .rect(cornerRadius: CornerRadius.md))
        }
    }
}

//The rows: a bold day holding a meeting or lenses, or a lighter, shorter row for a free day
extension PendingCalendar {

    private func dayRow(day: Date, faces: [Face], meeting: EventProfile?, showsDivider: Bool) -> some View {
        VStack(spacing: 0) {
            if let meeting { meetingDay(day: day, meeting: meeting) }
            else if faces.isEmpty { noEventDay(day: day) }
            else { eventDay(day: day, faces: faces) }

            if showsDivider {
                VeryLightDivider()
            }
        }
    }

    //Matches the Calendar View's free rows: the same 16pt as a busy day's date, only regular
    //weight, centred in a fixed row
    private func noEventDay(day: Date) -> some View {
        Text(FormatEvent.shortDayAndTime(day, withHour: false, withToday: true))
            .font(.body(16, .regular))
            .foregroundStyle(Color.textTertiary.opacity(0.7)) //Tad Lighter
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: Self.freeRowHeight)
    }

    private func eventDay(day: Date, faces: [Face]) -> some View {
        let hasPrimary = faces.contains { $0.isFirst }

        //.top: a wrapped pile grows downward while the day stays on its first line
        return HStack(alignment: .top, spacing: Spacing.md) {
            dayTitle(day: day, lineHeight: hasPrimary ? Self.lensFrame : Self.echoLens)

            Spacer(minLength: 0)

            facePile(day: day, faces: faces)
        }
        .padding(.vertical, hasPrimary ? Self.primaryPad : Self.echoPad)
    }

    //A meeting takes the whole day: one tinted lens on the rail, at a primary row's height
    private func meetingDay(day: Date, meeting: EventProfile) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            dayTitle(day: day, lineHeight: Self.lensFrame)

            Spacer(minLength: 0)

            Lens(face: (meeting, true),
                 lensID: meeting.id, //The bare event id: invite lenses carry "#day", so the two never share a selection
                 isMeeting: true,
                 selectedLensID: $selectedLensID,
                 onOpen: {},
                 card: meetingCard)
            .id(meeting.id) //A different meeting taking this day remounts the lens: its open card fades out, never flies home onto the new face
        }
        .padding(.vertical, Self.primaryPad)
    }

    private func dayTitle(day: Date, lineHeight: CGFloat) -> some View {
        Text(FormatEvent.shortDayAndTime(day, withHour: false, withToday: true))
            .font(.body(16, .bold))
            .foregroundStyle(Color.textPrimary)
            .oneLineLimitAndShrink() //"Tomorrow" beside a full four-lens line — shrink, never truncate
            .frame(height: lineHeight) //Geometry: centred on the pile's first line, wherever the pile wraps
    }

    //Always the whole window the composer could have proposed across, and never so few that an
    //invited day or a meeting falls off the end — a face the card cannot draw is an invite nobody answers
    private func days(booked: [Date: EventProfile]) -> [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let furthest = (inviteDays.map(\.day) + booked.keys).max() ?? start
        let span = max(ProposedTimes.horizonDays, (cal.dateComponents([.day], from: start, to: furthest).day ?? 0) + 1)

        return (0..<span).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    //The deadline always, and the rule a shared day raises only while some day actually holds
    //two invites — the case where one acceptance decides the others.
    private var acceptanceNote: String {
        let deadline = "They have until \(Int(ProposedTimes.acceptanceLead / 3600)) hours before the invite to accept.\nAs soon as one person accepts, your invite the others for that day expires."
        return deadline
//        guard inviteDays.contains(where: { $0.invites.count > 1 }) else { return deadline }
//        return deadline + "\n\nAs soon as one person accepts, your invite to the others for that day expires"
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
                        case .face(let face): lens(face, day: day)
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

    //One accepted event per day, keyed like the invite days. Two on one day keep the earlier time
    //(then the lower id), so the row never swaps between them as `session.events` reorders
    private var meetings: [Date: EventProfile] {
        let dated = upcomingEvents.compactMap { event in event.event.acceptedTime.map { (time: $0, event: event) } }
        return Dictionary(grouping: dated) { Calendar.current.startOfDay(for: $0.time) }
            .compactMapValues { sameDay in sameDay.min { ($0.time, $0.event.id) < ($1.time, $1.event.id) }?.event }
    }

    //A booked day gets no faces. It is skipped before `seen`, so an invite first proposed on a
    //booked day keeps its primary lens on the next day it still proposes
    private func ledger(skipping booked: Set<Date>) -> [Date: [Face]] {
        var seen: Set<String> = []
        var out: [Date: [Face]] = [:]

        for row in inviteDays.sorted(by: { $0.day < $1.day }) where !booked.contains(row.day) {
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

    private func lens(_ face: Face, day: Date) -> some View {
        Lens(face: face,
             lensID: "\(face.invite.id)#\(Int(day.timeIntervalSinceReferenceDate))",
             selectedLensID: $selectedLensID,
             onOpen: { onOpen(face.invite, day) },
             card: card)
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

//One lens: the face that lifts off, its glass ring, and the card that grows out of it. The
//presentation is the lens' own `.eventZoom` — the ledger keeps only which lens is up.
extension PendingCalendar {

    private struct Lens: View {

        //Injected
        let face: Face
        let lensID: String
        var isMeeting = false //An accepted event's lens: accent glass, and named as a meeting
        @Binding var selectedLensID: String?
        let onOpen: () -> Void
        let card: (EventProfile) -> AnyView

        //Id-guarded, like the tab cards' bindings: an evicted card's landed dismissal must never
        //drop a newer lens' selection
        private var isPresented: Binding<Bool> {
            Binding {
                selectedLensID == lensID
            } set: { presented in
                if presented { selectedLensID = lensID }
                else if selectedLensID == lensID { selectedLensID = nil }
            }
        }

        var body: some View {
            let name = face.invite.profile.name

            Button {
                onOpen() //First, in the same tap: the card's first body is built from the posed draft
                selectedLensID = lensID
            } label: {
                LensFace(face: face, tint: isMeeting ? .accent : nil)
            }
            .shrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
            .instantPressDelivery()
            .accessibilityLabel(isMeeting ? "Meeting \(name)" : face.isFirst ? name : "\(name) — alternative day")
            .eventZoom(isPresented: isPresented) {
                card(face.invite) //Built inside the card, so photos that load while it is up still reach it
            }
        }
    }

    //The lens' label — its own view, so it can read the anchor `.eventZoom` installs above it
    private struct LensFace: View {

        //Injected
        let face: Face
        var tint: Color? = nil //A meeting's accent — the resting glass and the close's landing rim wear the same one
        @Environment(EventZoomAnchor.self) private var anchor: EventZoomAnchor?

        var body: some View {
            let ring = face.isFirst ? PendingCalendar.glassRing : PendingCalendar.echoGlassRing

            //The face vacates at the tap (the source hides itself): the flying cover carries the
            //photo, and the close must land on a vacant glass ring — never on a duplicate image
            SmallImage(image: face.invite.image ?? UIImage(), size: face.isFirst ? PendingCalendar.faceSize : PendingCalendar.echoFaceSize, isCircle: true)
                .eventZoomSource(face.invite.image ?? UIImage(), shape: .circle(ring: ring, tint: tint)) //The close regrows the ring at this tier, in its tint
                .padding(ring)
                .lightShadow()
                .containerGlassEffect(tint: tint, clipped: true, shape: Circle())
                .opacity(anchor?.returning == true ? 0 : 1) //A committed close: the flight's own glass regrows the ring under the landing photo
                .padding(face.isFirst ? 0 : PendingCalendar.echoHitInset)
                .contentShape(Circle()) //PressButtonStyle sets none — without it the padding ring misses
                .padding(face.isFirst ? 0 : -PendingCalendar.echoHitInset)
        }
    }
}
