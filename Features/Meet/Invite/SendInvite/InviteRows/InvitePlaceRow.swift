//
//  InvitePlaceRow.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct InvitePlaceRow: View {
    
    @Binding var eventLocation: EventLocation?
    @Binding var showMapView: Bool
        
    var body: some View {
        HStack {
            if let location = eventLocation {
                addressText(location: location)
            } else {
                noLocationPlaceholder
            }
            Spacer()
            openMapButton
        }
        .frame(height: 50)
    }
}

extension InvitePlaceRow {
    
    private var noLocationPlaceholder: some View {
        Text("Place")
            .font(.body(20, .bold))
    }
    
    private var openMapButton: some View {
        Button {
            withAnimation(.snappy) { showMapView.toggle() }
        } label:  {
            Image("InvitePlace")
        }
    }
    
    private func addressText(location: EventLocation) -> some View {
        VStack(alignment: .leading) {
            Text(location.name ?? "")
                .font(.body(18, .bold))
            Text(EventFormatting.addressWithoutCountry(location.address))
                .font(.footnote)
                .foregroundStyle(.gray)
        }
    }
}
