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
    @Binding var showMapView: Bool
    
    let isMultipleTimes: Bool //If there are decrease topPadding as looks cleaner
    
    var body: some View {
        HStack {
            inviteTypeText(.where).opacity(ui.typePopupOpen ? 0.3 : 1)
            chooseButton
        }
    }
}

extension InvitePlaceRow {
    
    
    private var chooseButton: some View {
        Button {
            withAnimation(.snappy) { showMapView.toggle() }
        } label: {
            HStack(spacing: 12) {
                Group {
                    if let eventLocation {
                        VStack(alignment: .trailing) {
                            locationName(eventLocation)
                            locationAddress(eventLocation)
                        }
                    } else {
                        noLocationPlaceholder
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Image("InviteChevron")
            }
            .opacity(ui.timePopupOpenDelayed || ui.typePopupOpenDelayed ? 0 : 1)
        }
        .shrinkButton(shadow: nil, shadowColor: .clear)
    }
    
    private var noLocationPlaceholder: some View {
        Text("Choose Place")
            .font(.body(16, .regular))
            .foregroundStyle(Color(white: 0.4))
    }
    
    private func locationName(_ eventLocation: EventLocation)->  some View {
        Text(eventLocation.name ?? "")
            .font(.body(17, .medium))
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.trailing)
    }
    
    private func locationAddress(_ eventLocation: EventLocation) -> some View {
        
        Text(FormatEvent.addressBeforeFirstComma(eventLocation.address))
            .font(.footnote)
            .foregroundStyle(.gray)
            .lineLimit(1)
    }
}

