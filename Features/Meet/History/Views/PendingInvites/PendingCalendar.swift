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
    let ui: HistoryUIState //Read for the lens the flight stands on, and the dismiss pulse
    let onSelect: (EventProfile, CGRect) -> Void //Either lens of an invite opens the same card; the tap carries its face circle in global space

    //Local view state
    @State private var openDays: Set<Date> = [] //Days showing every face — the +N chip's own reveal
    @State private var faceRects = FaceRectStore() //A reference type: rects report on every scroll frame and must never invalidate the ledger

    //TODO: the composer proposes across 11 days (DayPicker.dayCount) — share one horizon constant when the data wiring lands
    private static let dayCount = 10

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

    //Four lenses is all one line holds beside its day — and at 52pt it is over budget: a long
    //label ("Wed Sep 30") renders at ~77% on a 393pt phone, and hits the 0.7 shrink floor and
    //truncates below that. Three per line is the fix if it shows.
    private static let facesPerLine = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HeaderRow(title: "Active", note: acceptanceNote)

            let faces = ledger //One pass, read ten times — not rebuilt per row
            let rows = days

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element) { index, day in
                    let mine = faces[day] ?? []
                    let hasNext = index + 1 < rows.count
                    let nextIsFree = hasNext && (faces[rows[index + 1]] ?? []).isEmpty
                    dayRow(day: day,
                           faces: mine,
                           showsDivider: hasNext && !(mine.isEmpty && nextIsFree))
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
            }
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
        //between the full day and the slim free day. Both paddings are derived, each giving
        //back exactly what its own lens took so neither tier's height moved.
        .padding(.vertical, hasPrimary ? Self.primaryPad : Self.echoPad)
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

    private func lens(_ face: Face, day: Date) -> some View {
        let lensID = "\(face.invite.id)#\(Int(day.timeIntervalSinceReferenceDate))"
        let isPulsed = ui.pulsedInvite == face.invite.id

        return Button {
            onSelect(face.invite, faceRects.rects[lensID] ?? .zero)
        } label: {
            SmallImage(image: face.invite.image ?? UIImage(), size: face.isFirst ? Self.faceSize : Self.echoFaceSize, isCircle: true)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { faceRects.rects[lensID] = $0 }
                .padding(face.isFirst ? Self.glassRing : Self.echoGlassRing)
                .imageShadow(hide: false)
                //Glass on its OWN layer, clipped there: crops the material's halo (the no-shadow floor — eleven
                //glowing circles read as noise) without cropping the image's shadow onto the lens above it
                .containerGlassEffect(clipped: true, shape: Circle())
                .circleStroke(lineWidth: 2, color: isPulsed ? .accent : .clear)
                .animation(.transition, value: isPulsed)
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

//Rects report continuously as the ledger scrolls; a plain reference type keeps those writes
//out of SwiftUI's invalidation entirely — the tap just reads the latest
private final class FaceRectStore {
    var rects: [String: CGRect] = [:]
}
