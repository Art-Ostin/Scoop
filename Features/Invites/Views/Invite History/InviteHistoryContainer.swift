//
//  InviteHistoryContainer.swift
//  Scoop
//
//  Created by Art Ostin on 30/08/2026.
//

import SwiftUI

struct InviteHistoryContainer: View {

    //Injected
    let event: UserEvent
    
    //Either face may still be loading: a missing one drops its avatar, never the page
    let profileImage: UIImage?
    let userImage: UIImage?

    @Environment(\.dismiss) private var dismiss

    //Local view state
    private static let title = "Invite History"
    private static let titleWidth = title.textWidth(font: .title(32, .bold)) //Measured in the bar's own font, so it tracks what's drawn

    var pastInvites: [PastEventProposal] {
        (event.pastProposals ?? []).reversed()
    }
    
    @State var isTopOfScroll = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 60) {
                    inviteSection(pastEvent: liveEvent(), isActiveRow: true)
                        .padding(.top, 48)
                    ForEach(pastInvites, id: \.self) {pastInvite in
                        inviteSection(pastEvent: pastInvite, isActiveRow: false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, Spacing.clearance)
            }
            .isAtTopOfScroll($isTopOfScroll)
            .background(Color(red: 0.97, green: 0.96, blue: 0.95).ignoresSafeArea())
            .navigationTitle(Self.title)
            .scoopNavigationBarFonts(title: Self.title) //Guarantees the bar draws the font titleWidth is measured in
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .heavy))
                    }
                }
            }
        }
    }
}

extension InviteHistoryContainer {
    
    
    private func inviteSection(pastEvent: PastEventProposal, isActiveRow: Bool) -> some View {
        let message = visibleMessage(pastEvent) //Decided once, so the spacing and the note can't disagree
        return VStack(spacing: 12) {
            titleRow(for: pastEvent, isActiveRow: isActiveRow)

            VStack(spacing: Spacing.lg) { //Above the rule: the note's break outweighs a row gap
                VStack(spacing: Spacing.xl) { //One row rhythm, note or not, so stacked cards line up
                    whatRowWithTime(what: pastEvent.type, time: pastEvent.dateSent)
                    whenRow(time: pastEvent.time, isNewTime: pastEvent.kind == .newTime)
                    whereRow(location: pastEvent.place)
                }

                if let message {
                    VStack(spacing: Spacing.lg) { //The same break below the rule as above it: the note's lowercase ink sits as far under it as the place row's baseline sits over it
                        LightDivider()
                            .padding(.leading, textColumn)
                        messageSection(message: message)
                    }
                }
            }
            .modifier(InviteBackground())
            .overlay(alignment: .bottomTrailing) {
                if isActiveRow {
                    Text("Current Invite")
                        .font(.title(14, .semibold))
                        .foregroundStyle(.accent)
                        .offset(y: 24)
                        .padding(.trailing, 5) //.horizontal
                }
            }
            .padding(.bottom, isActiveRow ? 12 : 0)
        }
    }
    
    private func titleRow(for proposal: PastEventProposal, isActiveRow: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            
            HStack(spacing: 12) {
                if let image = profileImage(for: proposal) {
                    smallTopImage(image: image)
                }
                
                Text(timeTitle(proposal))
                    .font(.title(17, .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()
            
            Text(proposal.kind == .original ? "Original Invite" : (proposal.kind == .newTime ? "New Time" : "New Event"))
                .font(.title(14, .bold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 5)//Optical illusion -> looks slightly smoother indented
    }
    
    
    
    
    private func smallTopImage(image: UIImage) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 45, height: 45)
            
            SmallImage(image: image, size: 35, isCircle: true)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 0)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 0)
        }
        .shrinkPress { }
    }

    
    private func timeTitle(_ proposal: PastEventProposal) -> String {
        let name = senderName(for: proposal)
        switch proposal.kind {
        case .original: return "\(name)" //'s original Invite
        case .newTime: return "\(name)" //proposed a new Time
        case .newEvent: return "\(name)" // proposed a new event
        }
    }
    
    private func whatRowWithTime(what: Event.EventType, time: Date) -> some View {
        HStack(alignment: .top) {
            HStack(spacing: iconGap) {
                Text(what.emoji)
                    .font(.body(14, .bold))
                    .detailIconColumn()

                sectionLayer(title: "WHAT", bodyText: what.longTitle)
            }
            Spacer()
            invitedTime(dateSent: time)
        }
        
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func whenRow(time: ProposedTimes, isNewTime: Bool) -> some View {
        HStack(spacing: iconGap) {
            Image(.eventClockIcon)
                .detailIconColumn()

            sectionLayer(title: "WHEN", bodyText: time.formatMultipleInvitedDays(), isBold: isNewTime)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func whereRow(location: EventLocation) -> some View {
        let text = location.name ?? location.address ?? "View Venue"
        
        return HStack(spacing: iconGap) {
            Image(.eventMapIcon)
                .detailIconColumn()

            sectionLayer(title: "WHERE", bodyText: text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private func invitedTime(dateSent: Date) -> some View {
        return Text(FormatEvent.dayMonthTime(dateSent))
            .font(.body(12, .medium))
    }
    
    private func sectionLayer(title: String, bodyText: String, isBold: Bool = false) -> some View {
        Text(bodyText)
            .font(.body(17, isBold ? .bold : .medium))
            .foregroundStyle(Color.textPrimary)
            .oneLineLimitAndShrink() //One line per detail row, so the card's rhythm never depends on the data
    }
    
    var dismissButton: some View {
        ScoopButton(style: .glass, shape: Circle(), size: .large) {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
    }
    
    //The header's face already says whose words these are, so the note wears none: it starts where the detail rows' text does
    private func messageSection(message: String) -> some View {
        Text(message)
            .font(.body(14, .italic))
            .lineSpacing(6)                          //Matches ConfirmMessageSection, so one note reads alike in both places
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, textColumn)
    }
}

extension InviteHistoryContainer {

    //senderId is an absolute user id — the repo arrayUnions one encoded snapshot onto BOTH users'
    //docs — so this reads correctly from either side of the negotiation.
    private func isFromOtherUser(_ proposal: PastEventProposal) -> Bool {
        proposal.senderId == event.otherUserId
    }

    private func senderName(for proposal: PastEventProposal) -> String {
        isFromOtherUser(proposal) ? event.otherUserName : "You"
    }

    //Their face rides the EventProfile the sheet was opened with; the user's own comes off the VM
    private func profileImage(for proposal: PastEventProposal) -> UIImage? {
        isFromOtherUser(proposal) ? profileImage : userImage
    }
    
    private func liveEvent() -> PastEventProposal {
        return PastEventProposal(retiring: event)
    }

    //A cleared note is saved as "", never nil, and whitespace counts as none.
    //Returns the trimmed text, so a trailing newline can't add a blank line
    private func visibleMessage(_ proposal: PastEventProposal) -> String? {
        guard let text = proposal.message?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return text
    }
}

private let iconColumn: CGFloat = 30 //Geometry: the emoji, clock and pin share one centre axis in it
private let iconGap = Spacing.md
private let textColumn = iconColumn + iconGap //Geometry: where every text line, and the rule, starts

private extension View {
    func detailIconColumn() -> some View {
        frame(width: iconColumn)
    }
}

struct InviteBackground: ViewModifier {

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg) //The same top and bottom whether or not a note closes the card
            .background(Color.white, in: .rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 7.5, x: 0, y: 1)
    }
}



/*
 //                photoSection
 private var photoSection: some View {
     HStack(spacing: 28) {
         if let profileImage {
             topImage(image: profileImage)
         }
         if let userImage {
             topImage(image: userImage)
         }
         Spacer()
     }
     .padding(.horizontal, 16)
     .padding(.vertical, 16)
     .padding(.bottom, 4)//some default padding between title and content.
     
 }
 
 private func topImage(image: UIImage) -> some View {
     ZStack {
         Circle()
             .fill(Color.white)
             .frame(width: 55, height: 55)
         
         SmallImage(image: image, size: 45, isCircle: true)
             .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 0)
             .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 0)
     }
     .shrinkPress { }
 }
 .overlay(alignment: .topLeading) {          // on the stack, not on its content
//            circlePhoto
//                .blurPop(visible: isTopOfScroll)    // .ignoresSafeArea() removed
//                .padding(.horizontal, 16)
//                .padding(.top, 20)
 }

 */
