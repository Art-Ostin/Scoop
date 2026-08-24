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
    let expiredInvites: [EventProfile]
    let activePendingInviteCount: Int
    let ui: HistoryUIState
    let defaults: DefaultsManaging //Only to read preferredMapType when a venue is tapped
    
    //Local view state
    @State private var openNotes: Set<DayNote> = []
    
    var body: some View {
        VStack(spacing: 0) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(inviteDays) { inviteDay in
                    Section {
                        dayCard(inviteDay)
                            .padding(.bottom, Spacing.xl) //Day → next day
                    } header: {
                        dayHeader(inviteDay)
                            .padding(.bottom, Spacing.sm) //Header → its card
                    }
                }
            }
            .padding(.horizontal, Spacing.gutter)
            
            Text("Active Pending Invites: \(activePendingInviteCount)")
                .font(.body(17, .medium))
                .foregroundStyle(Color(red: 0.34, green: 0.29, blue: 0.24))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, Spacing.xl) //The last day's card carries the matching xl above
                .padding(.top, -8)
            
            expiredSection
                .padding(.bottom, Spacing.clearance * 2)
                .padding(.horizontal, Spacing.gutter)
                .padding(.top, 12)
        }
    }
}





extension PendingInvitesView {
    
    private var expiredSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            expiredHeader
            
            expiredDetail
                .drawer(isOpen: ui.showsExpired)
        }
    }
    
    //The whole heading is the control, its chevron turning down as the section opens
    private var expiredHeader: some View {
        Button {
            withAnimation(.unfold) { ui.showsExpired.toggle() } //Not .expand: six invites is a tall reveal
        } label: {
            HStack {
                Text("Unanswered Invites")
                    .font(.body(18, .bold))
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body(15, .bold))
                    .foregroundStyle(Color.textSecondary)
                    .rotationEffect(.degrees(ui.showsExpired ? 90 : 0)) //Right → down, as the rows' own chevrons
                    .animation(.toggle, value: ui.showsExpired)
                    .padding(.trailing, 6) //Geometry: optical inset — the glyph's box is wider than its stroke
            }
            .expandHitArea(Spacing.sm) //One text line is a thin target, and the Spacer's gap carries no shape of its own
        }
        .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
    }
    
    //What the heading reveals: the note the section needs, then the card of unanswered invites
    private var expiredDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Invites where all your invited times have expired. They can still respond by proposing a new time.")
                .infoText()
                .padding(.top, Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !expiredInvites.isEmpty {
                expiredCard
                    .padding(.top, Spacing.sm) //Note → its card, as a day's header → card
            }
        }
        .padding(.top, Spacing.hairline) //The nudge the heading kept above its note
    }
    
    private var expiredCard: some View {
        VStack(spacing: 0) {
            ForEach(expiredInvites) { event in
                ExpiredEventCard(event: event,
                                 showsDivider: event.id != expiredInvites.last?.id,
                                 isExpanded: ui.expandedInvite == .expired(event.id),
                                 defaults: defaults,
                                 onToggle: { toggleExpired(event) })
            }
        }
        .padding(.horizontal, Spacing.md) //Same as the row's avatar ↔ text gap
        .padding(.vertical, cardInset(count: expiredInvites.count))
        .frame(maxWidth: .infinity)
        .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
    }
}


//The day's heading, with an info note on the days that need explaining
extension PendingInvitesView {
    
    @ViewBuilder
    private func dayHeader(_ inviteDay: InviteDay) -> some View {
        let note = note(for: inviteDay)
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.xs) {
                Text(FormatEvent.shortDayAndTime(inviteDay.day, withHour: false, withToday: true))
                    .font(.body(18, .bold))
                    .foregroundStyle(Color.textPrimary)
                
                Spacer(minLength: 0)
                
                if let note {
                    infoButton(note)
                        .padding(.trailing, Spacing.xs)
                }
            }
            
            if let note {
                RevealingInfoText(text: note.text, isOpen: openNotes.contains(note))
            }
        }
    }
    
    private func infoButton(_ note: DayNote) -> some View {
        Button {
            withAnimation(.expand) {
                if openNotes.contains(note) { openNotes.remove(note) } else { openNotes.insert(note) }
            }
        } label: {
            SmallInfoIcon()
                .expandHitArea()
        }
        .growButton()
        .accessibilityLabel(note.text)
    }
    
    //Today, or the first other day holding more than one invite
    private func note(for inviteDay: InviteDay) -> DayNote? {
        if inviteDay.isToday { return inviteDay.hasMultipleInvites ? .todayMultiple : .today }
        guard !todayCarriesTheMultipleRule else { return nil }
        
        let firstMultiDay = inviteDays.first { $0.hasMultipleInvites && !$0.isToday }
        return inviteDay.id == firstMultiDay?.id ? .multipleInvites : nil
    }
    
    //Today's note already spells the rule out, so no later day repeats it
    private var todayCarriesTheMultipleRule: Bool {
        inviteDays.contains { $0.isToday && $0.hasMultipleInvites }
    }
    
    private var totalInvitesPendingText: some View {
        Text("Total Pending Invites: \(inviteDays.count)")
    }
}

//The white card a day's invites sit in
extension PendingInvitesView {
    
    private func dayCard(_ inviteDay: InviteDay) -> some View {
        VStack(spacing: 0) {
            ForEach(inviteDay.invites) {pending in
                InvitedCard(pending: pending,
                            showsDivider: pending.id != inviteDay.invites.last?.id,
                            isExpanded: ui.expandedInvite == .pending(pending.id),
                            defaults: defaults,
                            onToggle: { toggle(pending) })
            }
        }
        .padding(.horizontal, Spacing.md) //Same as the row's avatar ↔ text gap
        .padding(.vertical, cardInset(count: inviteDay.invites.count))
        .frame(maxWidth: .infinity)
        .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
    }
    
    //Each row carries Spacing.xs of its own, so the card adds only the remainder
    private func cardInset(count: Int) -> CGFloat {
        Spacing.md - Spacing.xs - (count == 1 ? Spacing.hairline : 0)
    }
    
    private func toggle(_ pending: PendingInvite) {
        set(.pending(pending.id))
    }
    
    private func toggleExpired(_ event: EventProfile) {
        set(.expired(event.id))
    }
    
    //Tapping the open card closes it; tapping any other one moves the opening to it
    private func set(_ card: ExpandedCard) {
        withAnimation(.expand) {
            ui.expandedInvite = ui.expandedInvite == card ? nil : card
        }
    }
}

//What a day's info icon explains
private enum DayNote {
    case today
    case multipleInvites
    case todayMultiple //Today, holding more than one invite: both rules at once
    
    var text: String { // TODO: final copy
        let hours = Int(ProposedTimes.acceptanceLead / 3600)

        return switch self {
        case .today: "They have until \(hours) hours before the invite to accept"
        case .multipleInvites: "As soon as one person accepts, your invite to the others for that day expires"
        case .todayMultiple: "They have until \(hours) hours before the invite to accept. As soon as one person accepts, your invite to the others for today expires"
        }
    }
}
