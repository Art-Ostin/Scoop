//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

enum DetailInfo: CaseIterable {
    
    case time, message, event
    
    func title(_ event: UserEvent) -> String {
        switch self {
        case .time: return "Select A Time"
        case .message: return "Message"
        case .event: return event.type.title
        }
    }
    
    func message(_ event: UserEvent) -> String {
        switch self {
        case .time:
            return "Select a time \(event.otherUserName) proposed or suggest a new time or event"
        case .message:
            return "Once accepted, message to sort out details and to find one another"
        case .event:
            return event.type.howItWorks(userEvent: event)
        }
    }
    
    var image: String {
        switch self {
        case .time: return "MiniClockIcon"
        case .message: return "SmallMessageIcon"
        case .event: return "FilledCup"
        }
    }
}
struct RespondDetailsCard: View {
    
    let event: UserEvent
    @Binding var isFlipped: Bool
    
    let image: UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            title
            ForEach(DetailInfo.allCases, id: \.self) {detail in
                DetailSection(event: event, type: detail)
            }
        }
        .lineSpacing(4)
        .padding(.top, 18)
        .padding(.horizontal, 22)
        .padding(.bottom, 40)
        .overlay(alignment: .bottomTrailing) {
            inviteButton
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 24)
        .offset(y: 36)
    }
}

extension RespondDetailsCard {
    
    private var title: some View {
        Text("How it Works")
            .font(.custom("SFProRounded-Bold", size: 18))
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var inviteButton: some View {
        Button {
            isFlipped.toggle()
        } label: {
            HStack {
                CirclePhoto(image: image, showShadow: false, height: 24)
                
                Text("Invite")
                    .font(.body(14, .bold))
                    .foregroundStyle(Color.appGreen)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.appGreen.opacity(0.05))
            )
            .stroke(24, lineWidth: 1, color: .appGreen.opacity(0.5))
        }
    }
}

private struct DetailSection: View {
    let event: UserEvent
    let type: DetailInfo
    
    var body: some View {
        HStack(spacing: 16) {
            Image(type.image)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title(event))
                    .font(.body(16, .medium))
                
                Text(type.message(event))
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
