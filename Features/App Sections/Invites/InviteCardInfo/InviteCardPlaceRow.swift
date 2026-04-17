//
//  InviteCardPlace.swift
//  Scoop
//
//  Created by Art Ostin on 10/04/2026.
//

import SwiftUI

struct InviteCardPlaceRow: View {
    
    let location: EventLocation
    let isMeetUp: Bool
    var body: some View {
        HStack (spacing: 6) {
            locationSection
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            
        }
    }
}

extension InviteCardPlaceRow {
    
    private enum Palette {
        static let primaryText = Color(red: 0.2, green: 0.21, blue: 0.24)
        static let secondaryText = Color.grayText
    }
        
    private var locationSection: some View {
        HStack(spacing: isMeetUp ? 24 : 12) {
            Image(isMeetUp ? "GoogleMapsIcon" : "MiniMapIcon")
//                .scaleEffect(isMeetUp ? 1.2 : 1)
            placeDetails
        }
    }
    
    private var placeDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            placeName
            placeAddress
        }
    }
    
    private var placeName: some View {
        Text(location.name ?? "")
            .font(.body(isMeetUp ? 18 : 15, .medium))
            .foregroundStyle(Palette.primaryText)
    }
    
    private var placeAddress: some View {
        Text(FormatEvent.addressWithoutCountry(location.address))
            .font(.body(isMeetUp ? 11 : 12, .medium))
            .underline()
            .foregroundStyle(isMeetUp ? Color(red: 0.65, green: 0.65, blue: 0.65) : Palette.secondaryText)
            .lineLimit(1)
    }
}

/*
 //            ViewMessageButton() {onTap()}
 //                .fixedSize()
 */
