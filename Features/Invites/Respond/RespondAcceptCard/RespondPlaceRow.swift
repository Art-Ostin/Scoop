//
//  RespondPlace.swift
//  Scoop
//
//  Created by Art Ostin on 05/04/2026.
//

import SwiftUI

struct RespondPlaceRow: View {
    @Binding var showMessageScreen: Bool
    
    let location: EventLocation
    
    var body: some View {
        HStack(spacing: 0) {
            Image("MiniMapIcon")
                .padding(.trailing, 24)
            eventNameAndAddress
                .layoutPriority(1)
            Spacer(minLength: 12)
            addMessageButton
                .fixedSize()
        }
    }
}

extension RespondPlaceRow {
    
    private var addMessageButton: some View {
        Button {
            showMessageScreen = true
        } label : {
            Image("AddMessageIcon")
                .padding(12)
                .contentShape(Rectangle())
                .padding(-12)
                .padding(6)
                .background(
                    Circle()
                        .foregroundStyle(Color.white)
                )
                .surfaceShadow(.floating, strength: 0.5)
        }
    }
    
    private var eventNameAndAddress: some View {
        VStack(alignment: .leading, spacing: 4) {
                Text(location.name ?? "")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                
                Text(FormatEvent.addressWithoutCountry(location.address))
                    .font(.body(12, .medium))
                    .underline()
                    .foregroundStyle(Color(red: 0.72, green: 0.72, blue: 0.72))
                    .lineLimit(1)
        }
    }
}


