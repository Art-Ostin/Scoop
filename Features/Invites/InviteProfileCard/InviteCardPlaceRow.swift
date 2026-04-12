//
//  InviteCardPlace.swift
//  Scoop
//
//  Created by Art Ostin on 10/04/2026.
//

import SwiftUI

struct InviteCardPlaceRow: View {
    
    let location: EventLocation
    
    
    var body: some View {
        
        HStack(spacing: 12) {
            Image("MiniMapIcon")
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name ?? "")
                    .font(.body(16, .medium))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                
                Text(FormatEvent.addressWithoutCountry(location.address))
                    .font(.body(12, .medium))
                    .underline()
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .lineLimit(1)
            }
        }
    }
    
    private func address() -> String {
        String([location.name, location.address]
                .compactMap { $0 }
                .joined(separator: ", ")
                .prefix(40)
        )
    }
}

//defiant gatekeeper
//Predictive History


