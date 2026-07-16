//
//  InvitePlaceRow.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

struct InvitePlaceRow: View {
    
    //Injected
    @Bindable var ui: TimeAndPlaceUIState
    @Binding var eventLocation: EventLocation?

    var body: some View {
        HStack {
            RowCaption(label: .where, dimmed: ui.isPopupOpen(.type))
            chooseButton
        }
        .blurPop(visible: !ui.delayedTimePopupOpen, scale: 1)
    }
}

extension InvitePlaceRow {
    
    
    private var chooseButton: some View {
        Button {
            withAnimation(.present) { ui.showMapView.toggle() }
        } label: {
            HStack(spacing: Spacing.sm) {
                Group {
                    if let eventLocation {
                        locationNameAndAddress(eventLocation)
                    } else {
                        noLocationPlaceholder
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                DropDownButton(isOpen: ui.showMapView)
            }
            .frame(height: InviteRowMetrics.rowHeight)
            .opacity(ui.isPopupOpenDelayed() ? 0 : 1)
        }
        .shrinkButton()
    }
    
    private var noLocationPlaceholder: some View {
        Text("Choose Place")
            .font(.body(16, .regular))
            .foregroundStyle(Color.textSecondary)
    }
    
    
    private func locationNameAndAddress(_ location: EventLocation) -> some View {
        VStack(alignment: .trailing, spacing: Spacing.xxs) {
            Text(location.name ?? "")
                .font(.body(17, .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
            
            Text(FormatEvent.addressBeforeFirstComma(location.address))
                .font(.body(12, .regular))
                .foregroundStyle(Color.textPlaceholder)
                .lineLimit(1)
        }
    }
}
