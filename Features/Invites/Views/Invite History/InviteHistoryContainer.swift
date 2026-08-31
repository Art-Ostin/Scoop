//
//  InviteHistoryContainer.swift
//  Scoop
//
//  Created by Art Ostin on 30/08/2026.
//

import SwiftUI

struct InviteHistoryContainer: View {

    //Injected
    let vm: InvitesViewModel
    let eventProfile: EventProfile

    @Environment(\.dismiss) private var dismiss

    //Local view state
    private static let title = "Invite History"
    private static let titleWidth = title.textWidth(font: .title(32, .bold)) //Measured in the bar's own font, so it tracks what's drawn

    var pastInvites: [PastEventProposal] {
        (eventProfile.event.pastProposals ?? []).reversed()
    }
    
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
            .background(Color(red: 0.97, green: 0.96, blue: 0.95).ignoresSafeArea())
            .navigationTitle(Self.title)
            .scoopNavigationBarFonts(title: Self.title) //Guarantees the bar draws the font titleWidth is measured in
            .scrollIndicators(.hidden)
            .task { await vm.ensureUserImageLoaded() }
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
            .overlay(alignment: .topLeading) {
                mainPhoto
                    .padding(.horizontal, 16) //Screen edge
                    .padding(.horizontal, Self.titleWidth) //Length of the title
                    .padding(.horizontal, 22) //Spacing between edge and content
                    .offset(y: -48)
            }
        }
    }
}

extension InviteHistoryContainer {
    
    @ViewBuilder
    private var mainPhoto: some View {
        if let image = eventProfile.image {
            SmallImage(image: image, size: 44, isCircle: true)
                .imageShadow(hide: false)
        }
    }
    
    private func inviteSection(pastEvent: PastEventProposal, isActiveRow: Bool) -> some View {
        VStack(spacing: 14) {
            titleRow(for: pastEvent, isActiveRow: isActiveRow)
            
            VStack(spacing: 18) {
                VStack(spacing: 18) {
                    whatRowWithType(what: pastEvent.type, kind: pastEvent.kind)
                    whenRow(time: pastEvent.time, isNewTime: pastEvent.kind == .newTime)
                    whereRow(location: pastEvent.place)
                }
                
                if let message = pastEvent.message {
                    LightDivider()
                    messageSection(proposal: pastEvent, message: message)
                }
            }
            .modifier(InviteBackground())
        }
    }
    
    private func titleRow(for proposal: PastEventProposal, isActiveRow: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(senderName(for: proposal))
                .font(.title(17, .bold))
                .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))

            Spacer()
            Text(isActiveRow ? "Current Invite" : FormatEvent.dayMonthTime(proposal.dateSent))
                .font(.title(14, .semibold))
                .foregroundStyle(isActiveRow ? .accent : Color(red: 0.65, green: 0.65, blue: 0.65))
            
        }
        .padding(.horizontal, 5)//Optical illusion -> looks slightly smoother indented
    }
    
    private func whatRowWithType(what: Event.EventType, kind: ProposalKind) -> some View {
        HStack(alignment: .top) {
            HStack(spacing: iconGap) {
                Text(what.emoji)
                    .font(.body(16, .bold))
                    .detailIconColumn()

                sectionLayer(title: "WHAT", bodyText: what.longTitle)
            }
            Spacer()
            invitedTypeIcon(type: kind)
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
    
    
    private func invitedTypeIcon(type: ProposalKind) -> some View {
        let text = type == .original ? "Original" : type == .newTime ? "New Time" : "New Event"
        
        return Text(text)
            .font(.body(10, .medium))
            .frame(width: 62, height: 19)
            .stroke(6.4, lineWidth: 1, color: Color.blackFill)
    }
    
    private func sectionLayer(title: String, bodyText: String, isBold: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs - 1) {
            Text(title)
                .font(.body(12, .medium))
                .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.81))
            
            Text(bodyText)
                .font(.body(17, isBold ? .bold : .medium))
                .foregroundStyle(Color.textPrimary)
        }
    }
    
    var dismissButton: some View {
        ScoopButton(style: .glass, shape: Circle(), size: .large) {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
    }
    
    private func messageSection(proposal: PastEventProposal, message: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            if let image = profileImage(for: proposal) {
                SmallImage(image: image, size: avatarSize, isCircle: true)
            }

            Text(message)
                .font(.body(14, .italic))
                .lineSpacing(6)                          //Matches ConfirmMessageSection, so one note reads alike in both places
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

extension InviteHistoryContainer {

    //senderId is an absolute user id — the repo arrayUnions one encoded snapshot onto BOTH users'
    //docs — so this reads correctly from either side of the negotiation.
    private func isFromOtherUser(_ proposal: PastEventProposal) -> Bool {
        proposal.senderId == eventProfile.event.otherUserId
    }

    private func senderName(for proposal: PastEventProposal) -> String {
        isFromOtherUser(proposal) ? eventProfile.event.otherUserName : "You"
    }

    //Their face rides the EventProfile the sheet was opened with; the user's own comes off the VM
    private func profileImage(for proposal: PastEventProposal) -> UIImage? {
        isFromOtherUser(proposal) ? eventProfile.image : vm.userImage
    }
    
    private func liveEvent() -> PastEventProposal {
        return PastEventProposal(retiring: eventProfile.event)
    }
}



private let iconColumn: CGFloat = 16
private let iconGap = Spacing.lg
private let avatarSize: CGFloat = 30

private extension View {
    func detailIconColumn() -> some View {
        frame(width: iconColumn)
    }
}

struct InviteBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 18)
            .background(Color.white, in: .rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 7.5, x: 0, y: 1)
    }
    
    
}
