//
//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct AcceptInvitePopup: View {
    
    @Bindable var ui: ProfileUIState
    
    let event: UserEvent
    let image: UIImage?
    let name: String
    
    let onAccept: (UserEvent) -> ()
    
    @State var isFlipped: Bool = false
    
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 22){
                popupTitle
                timeRow
            }
            placeRow
            actionSection
        }
        .animation(.easeInOut, value: isFlipped)
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 24)
        .offset(y: 12)
    }
}


extension AcceptInvitePopup {
    
    private var inviteDetailsScreen: some View {
        VStack {
            HStack {
                Text(event.type.description.emoji)
                Text(event.type.description.label)
                Spacer()
                acceptInviteScreen
            }
            .font(.custom("SFProRounded-Bold", size: 24))
            
            Text(event.type.howItWorks(userEvent: event))
        }
    }

    @ViewBuilder
    private var acceptInviteScreen: some View {
        VStack(alignment: .leading, spacing: 22){
            popupTitle
            timeRow
        }
        placeRow
        actionSection
    }
    
    private var backToEvent: some View {
        Text("Event")
            .foregroundStyle(Color.appGreen)
            .contentShape(.rect)
            .onTapGesture {
                isFlipped.toggle()
            }
    }
    
    private var popupTitle: some View {
        HStack(alignment: .center) {
            eventTitle
            Spacer()
            eventInfoButton
        }
    }
    
    private var eventTitle: some View {
        HStack(spacing: 8) {
            if let image {
                CirclePhoto(image: image, showShadow: false, height: 30)
            }
            Text("Meet \(name)")
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    }
    
    private var eventInfoButton: some View {
        Button {
            isFlipped = true
        } label: {
            HStack(spacing: 2) {
                Text("\(event.type.description.emoji) \(event.type.title)")
                    .font(.body(16, .medium))
                
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.grayText).opacity(0.6)
                    .font(.body(14, .medium))
                    .offset(y: -6)
            }
        }
    }
    
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
                    Text(addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .underline()
                        .lineLimit(1)
                }
            }
        }
    }
    
    private func addressWithoutCountry(_ address: String?) -> String {
        let parts = (address ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return parts.dropLast().joined(separator: ", ")
    }
    
    
    private var actionSection: some View {
        HStack {
            declineButton
            Spacer()
            acceptButton
        }
    }
    
    private var declineButton: some View {
        Button {

        } label: {
            Text("Decline")
                .font(.body(16, .bold))
                .foregroundStyle(Color(red: 0.36, green: 0.36, blue: 0.36))
                .padding(.horizontal, 36)
                .frame(height: 40)
                .stroke(16, lineWidth: 1.5, color: Color(red: 0.84, green: 0.84, blue: 0.84))
        }
    }
    
    private var acceptButton: some View {
        Button {
            onAccept(event)
        } label: {
            Text("Accept")
                .foregroundStyle(Color.white)
                .font(.body(16, .bold))
                .padding(.horizontal, 36)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.appGreen)
                )
        }
    }
}

struct CardBackground: View {
    var body: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.background)
                .shadow(color: .appGreen.opacity(0.1), radius: 5, x: 0, y: 4)
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
        }
    }
}
