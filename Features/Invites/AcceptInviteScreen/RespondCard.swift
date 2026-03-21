//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondCard: View {
    
    @Bindable var ui: ProfileUIState
    @Binding var isFlipped: Bool
    
    let event: UserEvent
    let image: UIImage
    let name: String
    
    let onAccept: (UserEvent) -> ()
    let onDecline: (UserEvent) -> ()
    
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 22) {
                popupTitle
                timeRow
            }
            placeRow
            actionSection
        }
        .modifier(CardContainerModifier())
    }
}

//PopupTitle Section
extension RespondCard {
    
    private var popupTitle: some View {
        HStack(alignment: .center) {
            eventTitle
            Spacer()
            eventInfoButton
        }
    }
    
    private var eventTitle: some View {
        HStack(spacing: 8) {
            CirclePhoto(image: image, showShadow: false, height: 30)
            Text("Invite") //Meet \(name)
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    }
    
    private var eventInfoButton: some View {
        Button {
            isFlipped = true
        } label: {
            HStack(alignment: .top, spacing: 2) {
                Text("\(event.type.description.emoji) \(event.type.title)")
                    .font(.body(16, .medium))
                
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.grayText).opacity(0.6)
                    .font(.body(14, .medium))
            }
        }
    }
}
extension RespondCard {
    
    private var timeRow: some View {
        
        HStack(spacing: 24) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
            
            VStack(alignment: .leading, spacing: 4) {
                if let first = event.proposedTimes.firstAvailableDate {
                    if let message = event.message {
                        Text(EventFormatting.fullDateAndTime(first))
                            .font(.body(16, .medium))
                        
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    } else {
                        Text(EventFormatting.fullDate(first, wideMonth: true))
                        
                        Text(EventFormatting.hourTime(first))
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    private var placeRow: some View {
        HStack(spacing: 24) {
            Image("MiniMapIcon")
                .scaleEffect(1.3)
                .foregroundStyle(Color.appGreen)
            
            VStack {
                let location = event.location
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(16, .medium))
                    Text(EventFormatting.addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .underline()
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var actionSection: some View {
        HStack {
            DeclineButton {onDecline(event) }
            Spacer()
            AcceptButton {onAccept(event)}
        }
    }
}


struct CardContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(CardBackground())
            .padding(.horizontal, 24)
            .offset(y: 12)
    }
}
