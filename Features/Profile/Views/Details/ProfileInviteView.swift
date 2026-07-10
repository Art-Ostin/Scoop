//
//  ProfileInviteView.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct ProfileInviteView: View {
    
    let event: UserEvent
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            typeRow
            timeRow
            placeRow
        }
    }
}

extension ProfileInviteView {
    private var typeRow: some View {
        
        HStack(spacing: Spacing.md) {
            Text(event.type.emoji)
                .font(.body(20, .medium))
            
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                (
                    Text("\(event.type.title): ")
                        .font(.body(16, .medium))
                    +
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                )
            }
        }
    }
    
    private var timeRow: some View {
        
        HStack(spacing: Spacing.lg) {
            Image("MiniClockIcon")
                .scaleEffect(1.3)
            
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
            if let first = event.proposedTimes.firstAvailableDate {
                Text(FormatEvent.dayAndTime(first, wide: true, withHour: false))
                    .font(.body(16, .medium))

                    Text(FormatEvent.hourTime(first))
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    private var placeRow: some View {
        HStack(spacing: Spacing.lg) {
            Image("MiniMapIcon")
                .scaleEffect(1.3)
                .foregroundStyle(Color.successGreen)

            VStack {
                let location = event.location
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(16, .medium))
                    Text(FormatEvent.addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}
