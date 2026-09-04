//
//  InviteCardOverlay.swift
//  Scoop Test
//
//  Created by Art Ostin on 04/09/2026.
//

import SwiftUI


private let hPadding = Spacing.lg

//Main Overlay of the card
struct InviteCardOverlay: View {
        
    let e: UserEvent
    let name: String
    let openInvite: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(name)
                .font(.title(26, .bold))
                .foregroundStyle(Color.white)
                .eventZoomTitleSource(name) //Flies into the respond card's "<name>'s Invite"
            
            lineSection(.whiteClock, fetchDay())
            lineSection(.whiteMap, e.location.name ?? "Unknown")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, hPadding)
        .padding(.bottom, 28)
        .overlay(alignment: .topTrailing) { typeAndInfoButton}
        .overlay(alignment: .bottomTrailing) {inviteButton}
    }
}


extension InviteCardOverlay {
    
    
    private func lineSection(_ image: ImageResource, _ text: String) -> some View {
        HStack(spacing: 20) {
            Image(image)
                .scaleEffect(1.2)
                .frame(width: 20)
                .offset(y: -2)//Fine tuned so in centre
            
            Text(text)
                .font(.body(20, .medium))
                .foregroundStyle(Color.white)
        }
    }
    
    private var typeAndInfoButton: some View {
        Button {
            
        } label: {
            HStack(alignment: .center, spacing: Spacing.xxs + 2) {
                Text(e.type.emoji)
                    .font(.body(13))
                
                Text(e.type.longTitle)
                    .font(.body(13, .bold))
            }
            .scaleEffect(0.9)
            .foregroundStyle(Color.white)
            .frame(height: 25)
            .padding(.trailing, 7)
            .padding(.leading, 5) //Leading edge bit extra padding
            .capsuleStroke(lineWidth: 1, color: .white.opacity(0.6))
            .padding(.top, 3.5)
            .padding(.trailing, hPadding)
            .expandHitArea()
        }
        .shrinkButton()
    }
    
    private func fetchDay() -> String {
        if let date = e.proposedTimes.firstAvailableDate {
            return FormatEvent.shortDayAndTime(date)
        } else {
            return "Choose Time"
        }
    }
    
    private var inviteButton: some View {
        InviteButton(onTap: openInvite)
        .padding(.horizontal, hPadding)
        .padding(.bottom, 26) //28 + 4
    }
}


//The 'Respond Card'

struct InviteHistoryButton: View {
    
    //Passed it in for binding and conditional propality isolated to this Icon
    @Binding var showInviteHistory: EventProfile?
    let eventProfile: EventProfile
    
    
    var body: some View {
        if eventProfile.event.pastProposals != nil {
            if let kind = eventProfile.event.proposedKind {
                ScoopButton(style: .glass, shape: .capsule) {
                    showInviteHistory = eventProfile
                } label: {
                    Text(kind.text(cardMode: true))
                        .font(.body(12, .bold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .foregroundStyle(Color.textPrimary)
                }
                .padding()
                .padding(.horizontal, 12)
                .expandHitArea()
            }
        }
    }
}
