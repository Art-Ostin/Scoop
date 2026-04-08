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
    }
}

extension InvitePlaceRow {
    
    private var noLocationPlaceholder: some View {
        Text("Select Place")
            .font(.body(15, .medium))
            .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
    }
    
    
    private func addressText(location: EventLocation) -> some View {
        VStack(alignment: .leading) {
            Text(location.name ?? "")
                .font(.body(16, .medium))
            Text(FormatEvent.addressWithoutCountry(location.address))
                .font(.footnote)
                .foregroundStyle(.gray)
                .lineLimit(1)
        }
    }
    
    private var openMapButton: some View {
        Button {
            withAnimation(.snappy) { showMapView.toggle() }
        } label: {
            Image("LightBlackMapIcon")
                .padding(6)
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
        }
        .buttonStyle(.plain)
        .padding(-14)
    }
}
