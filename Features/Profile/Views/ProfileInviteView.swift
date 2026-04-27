//
//  ProfileInviteView.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct ProfileInviteView: View {
    
    @Bindable var ui: ProfileUIState
    let event: UserEvent
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            typeRow
            timeRow
            placeRow
        }
    }
}

extension ProfileInviteView {
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
                Text(FormatEvent.dayAndTime(first, wide: true, withHour: false))
                    .font(.body(16, .medium))

                    Text(FormatEvent.hourTime(first))
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
                    Text(FormatEvent.addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}
