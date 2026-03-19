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
    
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            popupTitle
                .frame(maxWidth: .infinity, alignment: .center)
            typeRow
            timeRow
            placeRow
            acceptButton
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(22)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .padding(.horizontal, 24)
        .offset(y: 12)
    }
}


extension AcceptInvitePopup {

    private var popupTitle: some View {
        HStack(spacing: 8) {
            if let image {
                CirclePhoto(image: image, showShadow: false, height: 30)
            }
            Text("Meet \(name)")
                .font(.body(22, .bold))
        }
    }

    
    private var typeRow: some View {
        
        HStack(spacing: 16) {
            Text(event.type.description.emoji)
                .font(.body(20, .medium))
            
            
            VStack(alignment: .leading, spacing: 4) {
                (
                    Text("\(event.type.title): ")
                        .font(.body(16, .medium))
                    +
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                )
            }
        }
    }
    
    private var timeRow: some View {
        
        HStack(spacing: 24) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
            
            
            VStack(alignment: .leading, spacing: 4) {
                if let first = event.proposedTimes.firstAvailableDate {
                    Text(EventFormatting.fullDate(first))
                        .font(.body(16, .medium))
                    
                    Text(EventFormatting.hourTime(first))
                        .font(.footnote)
                        .foregroundStyle(.gray)
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
    
    private var cardBackground: some View {
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
