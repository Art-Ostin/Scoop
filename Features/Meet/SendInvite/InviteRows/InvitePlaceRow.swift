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
        HStack(spacing: 0) {
            Group {
                if let location = eventLocation {
                    addressText(location: location)
                } else {
                    noLocationPlaceholder
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            openMapButton
                .fixedSize()
        }
        .frame(height: 50)
    }
}

extension InvitePlaceRow {
    
    private var noLocationPlaceholder: some View {
        Text("Place")
            .font(.body(20, .bold))
    }
    
    
    private func addressText(location: EventLocation) -> some View {
        VStack(alignment: .leading) {
            Text(location.name ?? "")
                .font(.body(18, .bold))
            Text(FormatEvent.addressWithoutCountry(location.address))
                .font(.footnote)
                .foregroundStyle(.gray)
        }
    }
    
    private var openMapButton: some View {
        Button {
            withAnimation(.snappy) { showMapView.toggle() }
        } label: {
            Image("LightBlackMapIcon") //LightBlackMapIcon
                .padding(6.5)
                .background(
                    Circle().foregroundStyle(.white).opacity(0.7)
                )
                .overlay {
                    Circle()
                        .strokeBorder(Color.accent.opacity(0.5), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                .contentShape(Rectangle())
                .padding(14)
                .offset(x: 0.5)
        }
        .buttonStyle(.plain)
        .padding(-14)
        
    }
}
