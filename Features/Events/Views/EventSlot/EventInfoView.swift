//
//  EventDetailsView.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct EventInfoView: View {
    
    @Bindable var ui: EventUIState
    
    let event: UserEvent
    let openMaps: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                eventInfoTitle
                eventInfoTime
                eventInfoAddress
            }
            confirmedText
            showEventDetailsButton
        }
    }
}

extension EventInfoView {
        
    private var eventInfoTitle: some View {
        let otherPerson = event.otherUserName
        
        var text = ""
        switch event.type {
        case .drink:
            text = "Drink with \(otherPerson)"
        case .doubleDate:
            text = "Double Date with \(otherPerson)"
        case .socialMeet:
            text = "Social with \(otherPerson)"
        case .custom:
            text = "Custom Date with \(otherPerson)"
        }
        return Text(text)
            .font(.body(20, .bold))
    }
    
    private var eventInfoTime: some View {
        Text(FormatEvent.dayAndTime(event.acceptedTime ?? Date()))
            .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.32))
            .font(.body(16, .regular))
    }
    
    private var eventInfoAddress: some View {
        Button {
            openMaps()
        } label: {
            Text(FormatEvent.addressWithoutCountry(event.location.address ?? ""))
                .font(.body(12, .regular))
                .underline(color: .grayText)
                .foregroundStyle(Color.grayText)
                .frame(width: 300, alignment: .leading)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var confirmedText: some View {
        Group {
            Text("You’ve both confirmed so don’t worry, they’ll be there! If you stand them up you're ")
                .foregroundStyle(Color.grayText)
                .font(.body(16, .medium))

            + Text("blocked.")
                .font(.body(16, .bold))
                .underline()
                .foregroundStyle(Color.black)
        }
        .lineSpacing(8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var showEventDetailsButton: some View {
        Button {
            ui.showEventDetails = event
        } label: {
            HStack(spacing: 10) {
                Image("CoolGuys")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text(event.type.title)
                    .font(.body(17, .bold))
                    .foregroundStyle(Color.black)
            }
            .padding(6)
            .padding(.horizontal, 4)
            .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.background)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 2)
                )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
