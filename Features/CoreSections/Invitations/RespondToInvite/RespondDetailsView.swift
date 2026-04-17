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
        case .time: return "Time"
        case .message: return "Message"
        case .event: return "Meet"
        }
    }
    
    func message(_ event: UserEvent) -> String {
        switch self {
        case .time:
            return "Choose a time, or suggest a new one, or send \(event.otherUserName) a new invite."
        case .message:
            return "Once accepted, you can message to coordinate details and find each other."
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

struct RespondDetailsView: View {
    
    let event: UserEvent
    @Binding var showInfo: Bool
    let image: UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            title
            ForEach(DetailInfo.allCases, id: \.self) {detail in
                DetailSection(event: event, type: detail)
            }
        }
        .lineSpacing(4)
        .padding(.top, 18)
        .padding(.horizontal, 22)
        .padding(.bottom, 42)
        .overlay(alignment: .bottomTrailing) {
            inviteButton
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 24)
        .onTapGesture {
            showInfo.toggle()
        }
    }
}

extension RespondDetailsView {
    
    private var title: some View {
        Text(event.type.description.emoji + " " + event.type.longTitle)
            .font(.custom("SFProRounded-Bold", size: 18))
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var inviteButton: some View {
        Button {
            showInfo.toggle()
        } label: {
            HStack(spacing: 8) {
                CirclePhoto(image: image, showShadow: false, height: 24)
                
                Text("Invite")
                    .font(.custom("SFProRounded-Bold", size: 14))
                    .foregroundStyle(Color.appGreen)
            }
            .padding(.leading, 6)
            .padding(.trailing, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .foregroundStyle(Color.white.opacity(0.7))
            )
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            .stroke(100, lineWidth: 1, color: .green.opacity(0.1))
        }
    }
}

struct DetailSection: View {
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
