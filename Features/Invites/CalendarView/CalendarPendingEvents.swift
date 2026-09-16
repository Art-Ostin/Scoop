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

struct CalendarPendingEvents: View {

    //Injected
    let invites: [InviteDay]
    let acceptedEvents: [EventProfile]
    let onOpen: (EventProfile, Date) -> Void //Runs on tap, just before the card opens
    let card: (EventProfile) -> AnyView //.eventZoom wraps its card in AnyView anyway
    let meetingCard: (EventProfile) -> AnyView

    //Local view state
    @State private var selectedLensID: String? //Which avatar's card is open

    private static let rowHeight: CGFloat = 72
    private static let freeRowHeight: CGFloat = 40

    private static let facesPerLine = 3

    var body: some View {
        let booked = meetings
        let faces = ledger(skipping: Set(booked.keys)) //One pass, read once per row — not rebuilt per face
        let rows = days

        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element) { index, day in
                let hasNext = index + 1 < rows.count
                let isFree = (faces[day] ?? []).isEmpty && booked[day] == nil //Booked too: the ledger skips meeting days, so their faces are empty as well
                let nextIsFree = hasNext && (faces[rows[index + 1]] ?? []).isEmpty && booked[rows[index + 1]] == nil

                dayRow(day: day,
                       faces: faces[day] ?? [],
                       meeting: booked[day],
                       showsDivider: hasNext && !(isFree && nextIsFree))
            }
        }
    }
}

//Views
extension CalendarPendingEvents {

    //A hairline under every row but the last: the day and its faces sit a column apart, and the
    //rule is what says they are one row. Two free days back to back skip it — neither has faces to tie
    private func dayRow(day: Date, faces: [DayFace], meeting: EventProfile?, showsDivider: Bool) -> some View {
        let isActive = !faces.isEmpty || meeting != nil

        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.md) {
                dayLabel(for: day, isActive: isActive)
                    .frame(height: isActive ? Self.rowHeight : Self.freeRowHeight) //Centred on the row's first line, however far the pile wraps

                Spacer(minLength: 0)

                if let meeting {
                    meetingButton(meeting)
                        .frame(height: Self.rowHeight)
                } else {
                    let lines = lines(of: faces)
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
    private func facePile(_ lines: [[DayFace]], day: Date) -> some View {
        VStack(alignment: .trailing, spacing: Spacing.sm) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: Spacing.sm) {
                    ForEach(line) { face in
                        avatarButton(face: face, day: day)
                    }
                }
            }
        }
    }

    private func avatarButton(face: DayFace, day: Date) -> some View {
        //One invite can be on up to 3 days, so the ID includes the day, or all 3 avatars would open at once
        let lensID = "\(face.invite.id)#\(Int(day.timeIntervalSinceReferenceDate))"
        let name = face.invite.profile.name

        return Button {
            onOpen(face.invite, day) //First, so the card opens on the tapped day
            selectedLensID = lensID
        } label: {
            AvatarFace(image: face.invite.image, isFirst: face.isFirst)
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

    private var meetings: [Date: EventProfile] {
        Dictionary(acceptedEvents.compactMap { event in
            event.event.acceptedTime.map { (Calendar.current.startOfDay(for: $0), event) }
        }, uniquingKeysWith: { earlier, _ in earlier })
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

    private func lines(of faces: [DayFace]) -> [[DayFace]] {
        stride(from: 0, to: faces.count, by: Self.facesPerLine).map {
            Array(faces[$0..<min($0 + Self.facesPerLine, faces.count)])
        }
    }
}

//The avatar's look: its own view, so it can read the zoom state .eventZoom puts above it
struct AvatarFace: View {
    //Injected
    let image: UIImage?
    let isFirst: Bool
    var tint: Color? = nil

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
    //its neighbour — at Spacing.sm apart that lands on the 44pt minimum, and two echoes would
    //otherwise trade taps wherever their circles overlap
    static let echoHitInset = min((lensFrame - echoLens) / 2, Spacing.sm / 2)

    var body: some View {
        let rim = isFirst ? Self.ring : Self.echoRing
        let hitInset = isFirst ? 0 : Self.echoHitInset

        SmallImage(image: image ?? UIImage(), size: isFirst ? Self.faceSize : Self.echoFaceSize, isCircle: true)
            .background(Circle().fill(Color.fillGray)) //A face still loading is a grey disc, not an empty ring
            .eventZoomSource(image ?? UIImage(), shape: .circle(ring: rim, tint: tint)) //The photo that grows into the card; the close lands it wearing this ring's tint
            .padding(rim) //Geometry: the glass ring's width
            .lightShadow()
            .containerGlassEffect(tint: tint, clipped: true, shape: Circle())
            .opacity(anchor?.returning == true ? 0 : 1) //The closing flight draws its own ring, tint and all, so hide this one
            .padding(hitInset) //Geometry: grows the echo's tap circle to the 44pt minimum
            .contentShape(Circle()) //PressButtonStyle sets none — without it the padding ring misses
            .padding(-hitInset) //Geometry: gives the space back, so the echo lays out at its true size
    }
}
