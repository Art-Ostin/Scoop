//
//  InvitePlaceRow.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct InvitePlaceRow: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    @Bindable var ui: TimeAndPlaceUIState
    
    var body: some View {
        HStack {
            if let location = vm.event.location {
                addressText(location: location)
            } else {
                noLocationPlaceholder
            }
            Spacer()
            openMapButton
        }
        .frame(height: ui.rowHeight)
    }
}

extension InvitePlaceRow {
    
    private var noLocationPlaceholder: some View {
        Text("Place")
            .font(.body(20, .bold))
    }
    
    private var openMapButton: some View {
        Button {
            withAnimation(.snappy) { ui.showMapView.toggle() }
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
