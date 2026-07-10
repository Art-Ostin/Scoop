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
        case .time: "Time"
        case .message: "Message"
        case .event: "Meet"
        }
    }

    func message(_ event: UserEvent) -> String {
        switch self {
        case .time: "Choose a time, or suggest a new one, or send \(event.otherUserName) a new invite."
        case .message: "Once accepted, you can message to coordinate details and find each other."
        case .event: event.type.howItWorksWithEvent(event)
        }
    }

    var image: String {
        switch self {
        case .time: "MiniClockIcon"
        case .message: "SmallMessageIcon"
        case .event: "FilledCup"
        }
    }
}

struct RespondDetails: View {
    
    let event: UserEvent
    @Binding var showInfo: Bool
    let image: UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            title
            ForEach(DetailInfo.allCases, id: \.self) {detail in
                DetailSection(event: event, type: detail)
                    .lineSpacing(4)
            }
            inviteButton
        }
        //1. Card Background, overlay and tap behaviour
        .modifier(RespondCardBackground())//Same background as the acceptCard
        .onTapGesture {showInfo.toggle()}
    }
}

extension RespondDetails {
    
    private var title: some View {
        Text(event.type.emoji + " " + event.type.longTitle)
            .font(.title(18))
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var inviteButton: some View {
        ScoopButton(shape: Capsule()) {
            showInfo.toggle()
        } label: {
            HStack(spacing: 8) {
                SmallImage(image: image, size: 24, isCircle: true)
                
                Text("Invite")
                    .font(.title(14, .bold))
                    .foregroundStyle(Color.successGreen)
            }
            .padding(.leading, 2) //As Image
            .padding(.trailing, 6)
            .padding(.vertical, 2) //As Image so smalle
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
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
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
