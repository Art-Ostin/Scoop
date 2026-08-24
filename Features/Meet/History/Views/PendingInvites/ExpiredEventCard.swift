//
//  ExpiredEventCard.swift
//  Scoop
//
//  Created by Art Ostin on 23/08/2026.
//

import SwiftUI

struct ExpiredEventCard: View {

    //Injected
    let event: EventProfile
    let showsDivider: Bool //False on the last expired invite — nothing follows it to separate
    let isExpanded: Bool
    let onToggle: () -> Void

    //Derived once at construction — body reads them many times per evaluation
    private let parts: (leadingDays: String, lastDay: String, hour: String)
    private let naturalLineWidth: CGFloat //The assembled times line at full size, for the uniform shrink

    //Local view state
    @State private var timesWidth: CGFloat = 0 //What the open times row can span, driving the uniform shrink
    @Namespace private var dateFlight

    private static let avatar: CGFloat = 40
    private static let textColumn = avatar + Spacing.md //Geometry: where the text column starts, for what sits under it

    private static let typeSize: CGFloat = 13 //The two sizes the flying date morphs between
    private static let timesSize: CGFloat = 15
    private static let dateID = "lastDay"

    init(event: EventProfile, showsDivider: Bool, isExpanded: Bool, onToggle: @escaping () -> Void) {
        self.event = event
        self.showsDivider = showsDivider
        self.isExpanded = isExpanded
        self.onToggle = onToggle

        let parts = event.event.proposedTimes.splitMultipleInvitedDays()
        self.parts = parts

        //Measured at the Dynamic-Type-scaled size Font.custom actually lays out, or the shrink under-corrects
        let font = UIFont.body(UIFontMetrics(forTextStyle: .body).scaledValue(for: Self.timesSize), .regular)
        let line = parts.leadingDays + parts.lastDay + " · " + parts.hour
        naturalLineWidth = (line as NSString).size(withAttributes: [.font: font]).width
            + 2 //Geometry: NSString metrics run a hair under laid-out Text — the pad keeps a rounding pt from forcing an ellipsis
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onToggle()
            } label: {
                header
            }
            .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
            .instantPressDelivery()

            expandedDetail
                .padding(.leading, Self.textColumn)
                .padding(.bottom, Spacing.xs) //The row's own half of the gap; the rule below adds the rest

            if showsDivider {
                LightDivider()
                    .padding(.vertical, Spacing.xs) //With the row's own, 16 above and 16 below the rule
                    .padding(.leading, Self.textColumn)
            }
        }
        .overlay(alignment: .topLeading) { flyingDate } //Above the drawer's clip, so the flight is never guillotined mid-hop
    }
}

//The tappable header and the drawer of days, place, and message it opens
extension ExpiredEventCard {

    //The greedy name column pushes the chevron trailing; it centers on both lines, as the row opens as a whole
    private var header: some View {
        HStack(spacing: Spacing.md) {
            circlePhoto

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HistoryName(name: event.profile.name)
                typeRow
            }

            HistoryChevron(isExpanded: isExpanded)
        }
        .padding(.top, Spacing.xs)
        .contentShape(Rectangle()) //PressButtonStyle sets none — without it the row's gaps miss
    }

    //The type takes the name's second line. Its date is the flying overlay's collapsed perch:
    //an invisible twin holds the slot, and the separator fades as the date leaves
    private var typeRow: some View {
        HStack(spacing: 0) {
            Text(event.event.type.longTitle)
                .lineLimit(1)
            Text(" · ")
                .opacity(isExpanded ? 0 : 1) //Fades as the date departs; keeps its slot so nothing reflows
            datePlaceholder(isSource: !isExpanded)
        }
        .font(.body(Self.typeSize, .regular))
        .foregroundStyle(Color.textTertiary)
        //The invisible twin drops out of the flattened VoiceOver label — restore what the row shows
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isExpanded ? event.event.type.longTitle : "\(event.event.type.longTitle) · \(parts.lastDay)")
    }

    //Every day the invite offered, on one line — ending in the flying date's landing slot
    //and the hour it gains when open. The same string the confirm card's time row shows.
    private var timesRow: some View {
        HStack(spacing: 0) {
            Text(parts.leadingDays)
                .lineLimit(1) //The one flexible part: overflow below the shrink floor truncates here
            datePlaceholder(isSource: isExpanded)
            Text(" · \(parts.hour)")
                .fixedSize()
                .opacity(isExpanded ? 1 : 0) //The hour the date gains: fades in as it lands
        }
        .font(.body(Self.timesSize * timesScale, .regular)) //One factor on every part — the split row shrinks as one piece
        .foregroundStyle(Color.textSecondary)
        //The invisible twin drops out of the flattened VoiceOver label — restore what the row shows
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(parts.leadingDays + parts.lastDay + " · " + parts.hour)
        .frame(maxWidth: .infinity, alignment: .leading)
        .getWidth($timesWidth)
        .padding(.top, Spacing.xs) //Type → times: the same step the place row keeps below
    }

    //Invisible in both rows: holds the date's slot at the row's own size and anchors one end of the flight
    private func datePlaceholder(isSource: Bool) -> some View {
        Text(parts.lastDay)
            .fixedSize()
            .matchedGeometryEffect(id: Self.dateID, in: dateFlight, properties: .position, anchor: .leading, isSource: isSource)
            .opacity(0)
    }

    //The one visible copy of the date: position from whichever placeholder is live, size and
    //colour morphing in the same transaction that rolls the drawer
    private var flyingDate: some View {
        Text(parts.lastDay)
            .font(.body(Self.timesSize, .regular)) //Rendered at landing size; the collapsed perch is a scale, which animates where a font change can't
            .foregroundStyle(isExpanded ? Color.textSecondary : Color.textTertiary)
            .contentTransition(.interpolate) //Interpolates the colour flip; the string itself never changes
            .fixedSize()
            .scaleEffect(isExpanded ? timesScale : Self.typeSize / Self.timesSize, anchor: .leading)
            .matchedGeometryEffect(id: Self.dateID, in: dateFlight, properties: .position, anchor: .leading, isSource: false)
            .allowsHitTesting(false) //It rests over the tappable header — touches belong to the rows beneath
            .accessibilityHidden(true) //The rows' own labels speak the date; a floating copy would read out of order
    }

    //Replaces the single Text's minimumScaleFactor: the assembled line measured against the row's
    //width, one factor for every part so they can't shrink apart
    private var timesScale: CGFloat {
        guard timesWidth > 0, naturalLineWidth > timesWidth else { return 1 }
        return max(timesWidth / naturalLineWidth, TextShrink.floor) //Below the floor the leading days truncate, as the modifier did
    }

    @ViewBuilder
    private var circlePhoto: some View {
        if let image = event.image {
            SmallImage(image: image, size: Self.avatar, isCircle: true)
        }
    }

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            timesRow
            HistoryPlaceRow(location: event.event.location)
            HistoryMessageSection(message: event.event.message)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .drawer(isOpen: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
