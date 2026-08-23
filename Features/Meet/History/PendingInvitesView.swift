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
    
    //Local view state
    @State private var openNotes: Set<DayNote> = []
    
    var body: some View {
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
        .padding(.bottom, Spacing.clearance)
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
        if inviteDay.isToday { return .today }
        let firstMultiDay = inviteDays.first { $0.invites.count > 1 && !$0.isToday }
        return inviteDay.id == firstMultiDay?.id ? .multipleInvites : nil
    }
}

//The white card a day's invites sit in
extension PendingInvitesView {
    
    private func dayCard(_ inviteDay: InviteDay) -> some View {
        VStack(spacing: 0) {
            ForEach(inviteDay.invites) {pending in
                InvitedCard(pending: pending,
                            showsDivider: pending.id != inviteDay.invites.last?.id,
                            isExpanded: ui.expandedInvite == pending.id,
                            showsChevron: showsChevron(pending),
                            defaults: defaults,
                            onToggle: { toggle(pending) })
            }
        }
        .padding(.horizontal, Spacing.md) //Same as the row's avatar ↔ text gap
        .padding(.vertical, cardInset(inviteDay))
        .frame(maxWidth: .infinity)
        .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
    }
    
    //Each row carries Spacing.xs of its own, so the card adds only the remainder
    private func cardInset(_ inviteDay: InviteDay) -> CGFloat {
        Spacing.md - Spacing.xs - (inviteDay.invites.count == 1 ? Spacing.hairline : 0)
    }
    
    private func toggle(_ pending: PendingInvite) {
        withAnimation(.expand) {
            ui.expandedInvite = ui.expandedInvite == pending.id ? nil : pending.id
        }
    }
    
    //Hidden while another day's card for this same invite is open
    private func showsChevron(_ pending: PendingInvite) -> Bool {
        guard let open = ui.expandedInvite, open != pending.id else { return true }
        return open.inviteID != pending.id.inviteID
    }
}

//What a day's info icon explains
private enum DayNote {
    case today
    case multipleInvites
    
    var text: String { // TODO: final copy
        switch self {
        case .today: "Hello World is today"
        case .multipleInvites: "Hello world multiple days"
        }
    }
}
