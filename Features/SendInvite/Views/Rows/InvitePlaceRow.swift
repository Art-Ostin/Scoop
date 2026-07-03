//
//  InvitePlaceRow.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct InvitePlaceRow: View {
    
    @Bindable var ui: TimeAndPlaceUIState
    @Binding var eventLocation: EventLocation?
        
    var body: some View {
        HStack {
            RowCaption(label: .where, dimmed: ui.isPopupOpen(.type))
            chooseButton
        }
    }
}

extension InvitePlaceRow {
    
    
    private var chooseButton: some View {
        Button {
            withAnimation(.snappy) { ui.showMapView.toggle() }
        } label: {
            HStack(spacing: 12) {
                Group {
                    if let eventLocation {
                        locationNameAndAddress(eventLocation)
                    } else {
                        noLocationPlaceholder
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                DropDownButton(isOpen: ui.showMessageScreen)
            }
            .opacity(ui.isPopupOpenDelayed() ? 0 : 1)
        }
        .shrinkButton(shadow: nil, shadowColor: .clear)
    }
    
    private var noLocationPlaceholder: some View {
        Text("Choose Place")
            .font(.body(16, .regular))
            .foregroundStyle(Color.textSecondary)
    }
    
    
    private func locationNameAndAddress(_ location: EventLocation) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(location.name ?? "")
                .font(.body(17, .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
            
            Text(FormatEvent.addressBeforeFirstComma(location.address))
                .font(.body(12, .regular))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }
}

