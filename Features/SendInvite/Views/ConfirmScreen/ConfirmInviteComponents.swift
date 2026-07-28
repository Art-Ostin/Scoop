//
//  ConfirmInviteComponents.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct InviteTypeButton: View {
    let type: Event.EventType
    
    @Binding var showInfoSheet: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
                Text(type.emoji)
                    .font(.body(15))
                
                HStack(spacing: 2) {
                    Text(type.title)
                        .font(.body(14, .bold))
                        .foregroundStyle(Color.textPrimary.mix(with: Color.accent, by: 0.2)) //Subtle Tint of accent
                        .kerning(-0.1)
                    
                    Image(systemName:"info.circle")
                        .font(.body(9, .regular))
                        .foregroundStyle(Color.textPlaceholder.mix(with: Color.accent, by: 0.1)) //Subtle Tint of accent
                        .offset(y: -3)
                        .offset(x: 1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, type == .drink ? 6 : 8)
            .background(Color.accent.opacity(0.05).mix(with: Color.fillGray, by: 0.5), in: Capsule())
            .padding(.horizontal, 24)
            .shrinkPress {showInfoSheet = true}
            .offset(y: -1 - (type == .drink ? 0 : 1)) //aligns it vertically for some reason
            .scaleEffect(0.85, anchor: .trailing)
    }
}


struct WarningLabel: View {
    
    var body: some View {
        HStack(spacing: Spacing.md){
            Image("ConfirmIcon")
            
            Text("Not showing may result in a blocked account")
                .font(.body(14, .regular))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fillGray.opacity(0.5), in: .rect(cornerRadius: CornerRadius.sm))
        .padding(.horizontal, Spacing.margin)
        
    }
}


struct TimeAndPlaceSection: View {
    
    let proposedTimes: ProposedTimes
    let place: EventLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            timeRow
            placeRow
        }
        .font(.body(17, .medium))
    }
    
    private var timeRow: some View {
         lineSection(icon: .eventClockIcon, text: proposedTimes.formatMultipleInvitedDays())
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
     }

     private var placeRow: some View {
         lineSection(icon: .eventMapIcon, text: place.name ?? place.address ?? "View on map")
             .padding(.vertical, Spacing.xs)
             .shrinkPress(action: openMap)
             .padding(.vertical, -Spacing.xs)
             .accessibilityAddTraits(.isButton)
     }

     private func lineSection(icon: ImageResource, text: String) -> some View {
         HStack(spacing: Spacing.md) {
             Image(icon)
                 .frame(width: 20, alignment: .leading) //Geometry: icon column both rows align to
             Text(text)
         }
     }
    
    private func openMap() {
        MapsRouter.openGoogleMaps(item: place.mapItem, withDirections: false)
    }
}

