//
//  PendingInvitesView.swift
//  Scoop
//
//  Created by Art Ostin on 22/08/2026.
//

import SwiftUI

struct PendingInvitesView: View {
    
    //Injected
    let inviteDays: [InviteDay]
    let ui: HistoryUIState
    let defaults: DefaultsManaging //Only to read preferredMapType when a venue is tapped
    
    
    //Local view state — one flag per note kind, so the two explanations open independently
    @State private var showTodayInfo = false
    @State private var showMultipleDayInfo = false
    
    
    var body: some View {
        //spacing: 0 — the two gaps are owned separately below, so neither can move the other
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(inviteDays) { inviteDay in
                Section {
                    dayCard(inviteDay)
                        .padding(.bottom, Spacing.xl) //Day → next day
                } header: {
                    //spacing: 0 — the note carries its own gap inside the clamp, so a closed day
                    //keeps its rhythm exactly as it would with no note at all
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: Spacing.xs) {
                            dayHeader(inviteDay.day)
                            
                            Spacer(minLength: 0)
                            
                            if let note = note(for: inviteDay) {
                                infoButton(note)
                                    .padding(.trailing, Spacing.xs)
                            }
                        }
                        
                        if let note = note(for: inviteDay) {
                            DayNoteText(note: note, isShowing: isShowing(note))
                        }
                    }
                    .padding(.bottom, Spacing.sm) //A day's header → its card
                }
            }
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.bottom, Spacing.clearance)
    }
}

extension PendingInvitesView {
    
    //The note a day carries, if any — today, or the first OTHER day with more than one invite.
    //Exclusive by construction, so an icon always stands for exactly one note. Derived, never
    //latched: body runs any number of times and its results can be discarded, so a flag written
    //while building would both fire on the wrong day and go stale the moment anything redrew.
    private func note(for inviteDay: InviteDay) -> DayNote? {
        if Calendar.current.isDateInToday(inviteDay.day) { return .today }
        if inviteDay.id == firstMultiInviteDay { return .multipleInvites }
        return nil
    }
    
    private func isShowing(_ note: DayNote) -> Bool {
        switch note {
        case .today: showTodayInfo
        case .multipleInvites: showMultipleDayInfo
        }
    }
    
    private var firstMultiInviteDay: InviteDay.ID? {
        let calendar = Calendar.current
        return inviteDays.first { $0.invites.count > 1 && !calendar.isDateInToday($0.day) }?.id
    }

    private func dayCard(_ inviteDay: InviteDay) -> some View {
        VStack(spacing: 0) {
            ForEach(inviteDay.invites) {pending in
                InvitedCard(pending: pending,
                            showsDivider: pending.id != inviteDay.invites.last?.id,
                            isExpanded: ui.expandedInvite == pending.id,
                            showsChevron: !isShadowed(pending.id),
                            defaults: defaults,
                            onToggle: { toggle(pending) })
            }
        }
        .modifier(InvitedDayBackground(isSingle: inviteDay.invites.count == 1))
    }

    private func toggle(_ pending: PendingInvite) {
        withAnimation(.expand) {
            ui.expandedInvite = ui.expandedInvite == pending.id ? nil : pending.id
        }
    }

    //Not a label announcing a section — the day IS the content, so it wears its own type
    private func dayHeader(_ day: Date) -> some View {
        Text(FormatEvent.shortDayAndTime(day, withHour: false, withToday: true))
            .font(.body(18, .bold))
            .foregroundStyle(Color.textPrimary)
    }

    private func isShadowed(_ card: InviteCardID) -> Bool {
        guard let open = ui.expandedInvite else { return false }
        return open.inviteID == card.inviteID && open != card
    }
    
    private func infoButton(_ note: DayNote) -> some View {
        Button {
            withAnimation(.expand) {
                switch note {
                case .today: showTodayInfo.toggle()
                case .multipleInvites: showMultipleDayInfo.toggle()
                }
            }
        } label: {
            SmallInfoIcon()
                .expandHitArea()
        }
        .growButton()
        .accessibilityLabel(note.text)
    }
}

//What a day's info icon explains. One case per reason a day earns an icon, so the copy can never
//Rolled away, never removed: a view in a removal transition leaves layout at once and fades its
//leftover, so the note would still be dissolving after the card below had closed over it. The
//measured-height clamp is the one InvitedCard's drawer uses — the content below cuts the note off.
private struct DayNoteText: View {
    
    //Injected
    let note: DayNote
    let isShowing: Bool
    
    //Local view state
    @State private var height: CGFloat = 0
    
    var body: some View {
        Text(note.text)
            .infoText()
            .padding(.top, Spacing.xs) //The gap above it, revealed together with it
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true) //Keep every line — the clamp must not compress it
            .getHeight($height) //ABOVE the clamp, so it measures the natural height, not 0
            .frame(height: isShowing ? height : 0, alignment: .top)
            .clipped()
    }
}

//be ambiguous about which it is answering.
private enum DayNote {
    case today
    case multipleInvites
    
    var text: String {
        switch self {
        case .today: "Hello World is today"
        case .multipleInvites: "Hello world multiple days"
        }
    }
}

private struct InvitedCard: View {
    
    //Injected
    let pending: PendingInvite
    let showsDivider: Bool //False on the last invite of a day — nothing follows it to separate
    let isExpanded: Bool
    let showsChevron: Bool //False while another day's card for this same invite is open
    let defaults: DefaultsManaging //Whose maps app the venue opens in
    let onToggle: () -> Void
    
    //Local view state
    @State private var detailHeight: CGFloat = 0
    
    //Geometry: the one avatar module. The photo, the message and the rule all start on it, so the
    //three can't drift. 40 is the app's two-line avatar (the in-app banner), on the 4pt grid.
    private static let avatar: CGFloat = 40
    private static let textColumn = avatar + Spacing.md //Geometry: where the text column starts, for what sits under it
    
    private var invite: EventProfile { pending.invite }
    
    private var proposedTime: Date { pending.time.date }
    
    //Same rule as ConfirmMessageSection's checkMessage: whitespace-only counts as no message
    private var message: String? {
        guard let text = invite.event.message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }
        return text
    }
    
    //placeName falls through to "" when the location carries neither a name nor an address —
    //nil'd here so an empty line can't take a row's worth of height inside the drawer
    private var place: String? {
        let name = FormatEvent.placeName(invite.event.location)
        return name.isEmpty ? nil : name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                //Every row discloses, whether or not it carries a message: the chevron belongs to
                //the row, not to one piece of its detail, so a row can't gain or lose one as the
                //drawer fills out
                Button {
                    onToggle()
                } label: {
                    header
                }
                .subtleShrinkButton() //Not shrinkPress: its raw DragGesture claims the touch and the scroll never pans
                .instantPressDelivery() //The scroll ancestors would otherwise hold the press back ~150ms
                
                //Outside that Button, not inside its label: a Button's label is content, so a venue
                //nested in it could never take its own tap — and the row would shrink for a press
                //meant for Maps. Out here the venue outranks the drawer's tap by plain hit-testing.
                expandedDetail
                    .padding(.leading, Self.textColumn)
            }
            .padding(.bottom, Spacing.xs) //The row's own half of the gap; the rule below adds the rest
            
            if showsDivider {
                LightDivider()
                    .padding(.vertical, Spacing.xs) //With the row's own, 16 above and 16 below the rule
                    .padding(.leading, Self.textColumn)
            }
        }
    }
    
    //The rule and the drawer stay outside: the press scale must never touch chrome
    private var header: some View {
        HStack(spacing: Spacing.md) { //Centred, like every avatar row in the app
            circlePhoto
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                nameRow
                
                timeRow
            }
        }
        .padding(.top, Spacing.xs)
        .contentShape(Rectangle()) //PressButtonStyle sets none — without it the row's gaps miss
    }
    
    //The slot is always reserved: a profile without a photo keeps the column every other row aligns to
    @ViewBuilder
    private var circlePhoto: some View {
        if let image = invite.image {
            SmallImage(image: image, size: Self.avatar, isCircle: true)
        } else {
            Circle()
                .fill(Color.fillGray)
                .frame(width: Self.avatar, height: Self.avatar)
        }
    }
    
    //Baselined, not topped: two sizes of one face share a baseline, or the smaller one floats
    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            Text(invite.profile.name)
                .font(.body(16, .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Option \(pending.time.optionNumber)")
                .font(.body(13, .regular))
                .foregroundStyle(Color.textTertiary)
                .fixedSize() //The name truncates, never the label
        }
    }
    
    //Centred rather than baselined — the chevron is a glyph, and a baseline puts it too low
    private var timeRow: some View {
        HStack(spacing: Spacing.md) {
            Text("\(invite.event.type.longTitle) · \(FormatEvent.hourTime(proposedTime))")
                .font(.body(15, .regular))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            chevronSlot
        }
    }
    
    
    //The meta block's third line, not a paragraph — it wears timeRow's face and sits on the same
    //column, so revealing it reads as the row growing a line rather than opening a panel
    @ViewBuilder
    private var placeRow: some View {
        if let place {
            Button {
                //The place itself, never a route — and in whichever maps app the user picked
                //in Settings, which openMaps reads off preferredMapType
                MapsRouter.openMaps(defaults: defaults,
                                    item: invite.event.location.mapItem,
                                    withDirections: false)
            } label: {
                Text(place)
                    .font(.body(15, .regular))
                    .foregroundStyle(Color.textAccent) //Accent-hued type is the app's link (ChatEventView's venue)
                    .lineLimit(1)
                    .padding(.top, Spacing.xs) //Clear of the meta clump: it is a control, not a third meta line
                    .contentShape(Rectangle())
            }
            //The full shrink, not the subtle one: that register exists for a wide row whose
            //siblings hold still, and at a fifth of the travel a single short line barely moves
            .shrinkButton() //Not shrinkPress: its raw DragGesture would claim the scroll's pan
            .instantPressDelivery() //Land the press on touch-down, as the row's own Button does
            .frame(maxWidth: .infinity, alignment: .leading) //Outside the Button: the line's empty half still toggles
        }
    }
    
    private var chevronSlot: some View {
        Image(systemName: "chevron.right")
            .font(.icon(12, .semibold))
            .foregroundStyle(Color.textTertiary)
            .rotationEffect(.degrees(isExpanded ? 90 : 0)) //Right → down: opens in place, the app's disclosure idiom
            .animation(.toggle, value: isExpanded)
            .opacity(showsChevron ? 1 : 0)
            .blur(radius: showsChevron ? 0 : 6) //the .blurReplace look, without leaving layout
            .animation(.transition, value: showsChevron)
    }
    
    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 0) { //spacing: 0 — each line owns its own gap, as the rows above do
            placeRow
            
            if let message {
                Text(message)
                    .font(.body(14, .italic))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(6)
                    .padding(.top, Spacing.sm) //Paragraph separation: its own 6pt leading needs more than a line gap
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .getHeight($detailHeight)
        .frame(height: isExpanded ? detailHeight : 0, alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}

//The card every day's invites sit in
private struct InvitedDayBackground: ViewModifier {

    let isSingle: Bool
    
    //Every row already carries Spacing.xs of its own, so the card adds only the remainder
    private var vertical: CGFloat {
        Spacing.md - Spacing.xs - (isSingle ? Spacing.hairline : 0)
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.md) //Same token as the row's avatar ↔ text gap, so the avatar sits equidistant from the card edge and from the name
            .padding(.vertical, vertical)
            .frame(maxWidth: .infinity)
            .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
    }
}
