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
                    VStack(alignment: .leading, spacing: 0) {
                        dayHeader(inviteDay: inviteDay)
                        textInfo(inviteDay: inviteDay)
                    }
                    .padding(.bottom, Spacing.sm)
                }
            }
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.bottom, Spacing.clearance)
    }
}

//Logic to do with the header
extension PendingInvitesView {
    
    
    
    
    
    private func dayHeader(inviteDay: InviteDay) -> some View {
        HStack(spacing: Spacing.xs) {
            dayHeader(inviteDay.day)
            
            Spacer(minLength: 0)
            
            if let note = note(for: inviteDay) {
                infoButton(note)
                    .padding(.trailing, Spacing.xs)
            }
        }
    }
    
    @ViewBuilder
    private func textInfo(inviteDay: InviteDay) -> some View {
        if let note = note(for: inviteDay) {
            DayNoteText(note: note, isShowing: isShowing(note))
        }
    }
    
    //Build the note
    private func note(for inviteDay: InviteDay) -> DayNote? {
        if Calendar.current.isDateInToday(inviteDay.day) { return .today }
        if inviteDay.id == firstMultiInviteDay { return .multipleInvites }
        return nil
    }

    //Is it MultiInviteDay?
    private var firstMultiInviteDay: InviteDay.ID? {
        let calendar = Calendar.current
        return inviteDays.first { $0.invites.count > 1 && !calendar.isDateInToday($0.day) }?.id
    }

    
    private func isShowing(_ note: DayNote) -> Bool {
        switch note {
        case .today: showTodayInfo
        case .multipleInvites: showMultipleDayInfo
        }
    }
    
}






extension PendingInvitesView {
    
    
    
    
    
    

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
