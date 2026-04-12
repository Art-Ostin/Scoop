//
//  InviteCardPlace.swift
//  Scoop
//
//  Created by Art Ostin on 10/04/2026.
//

import SwiftUI

struct InviteCardPlaceRow: View {
    
    @Binding var showMessageSection: Bool
    let location: EventLocation
    
    var body: some View {
        HStack (spacing: 6) {
            locationSection
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            
            ViewMessageButton(showMessageSection: $showMessageSection)
                .fixedSize()
        }
    }
}

extension InviteCardPlaceRow {
        
    private var locationSection: some View {
        HStack(spacing: 12) {
            Image("MiniMapIcon")
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
            .font(.body(16, .medium))
            .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
    }
    
    private var placeAddress: some View {
        Text(FormatEvent.addressWithoutCountry(location.address))
            .font(.body(12, .medium))
            .underline()
            .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
            .lineLimit(1)
    }
}
