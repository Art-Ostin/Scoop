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

    private var contentHeight: CGFloat {
        eventLocation == nil
            ? InviteRowMetrics.singleLineContentHeight
            : InviteRowMetrics.locationContentHeight
    }

    private var topPadding: CGFloat {
        eventLocation == nil
            ? InviteRowMetrics.verticalPadding
            : InviteRowMetrics.populatedPlaceTopPadding
    }

    private var rowHeight: CGFloat {
        contentHeight + topPadding + InviteRowMetrics.verticalPadding
    }

    private var contentOffset: CGFloat {
        (topPadding - InviteRowMetrics.verticalPadding) / 2
    }

    var body: some View {
        HStack {
            RowCaption(label: .where, dimmed: ui.isPopupOpen(.type))
                .frame(height: InviteRowMetrics.primaryLineHeight)
                .offset(y: contentOffset)
            chooseButton
        }
        .frame(height: rowHeight)
        .blurPop(visible: !ui.delayedTimePopupOpen, scale: 1)
    }
}

extension InvitePlaceRow {
    
    
    private var chooseButton: some View {
        Button {
            withAnimation(.present) { ui.showMapView.toggle() }
        } label: {
            HStack(spacing: InviteRowMetrics.valueChevronSpacing) {
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
            .offset(y: contentOffset)
            .frame(height: rowHeight)
            .opacity(ui.isPopupOpenDelayed() ? 0 : 1)
        }
        .shrinkButton()
    }
    
    private var noLocationPlaceholder: some View {
        Text("Choose Place")
            .font(.body(16, .regular))
            .foregroundStyle(Color.textSecondary)
            .frame(height: InviteRowMetrics.primaryLineHeight)
    }
    
    
    private func locationNameAndAddress(_ location: EventLocation) -> some View {
        VStack(alignment: .trailing, spacing: InviteRowMetrics.locationLineSpacing) {
            Text(location.name ?? "")
                .font(.body(17, .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .frame(height: InviteRowMetrics.primaryLineHeight)
            
            Text(FormatEvent.addressBeforeFirstComma(location.address))
                .font(.body(12, .regular))
                .foregroundStyle(Color.textPlaceholder)
                .lineLimit(1)
                .frame(height: InviteRowMetrics.secondaryLineHeight)
        }
    }
}
