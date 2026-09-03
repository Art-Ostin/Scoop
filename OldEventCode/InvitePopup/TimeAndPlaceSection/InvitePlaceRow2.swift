//
//  InvitePlaceRow.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

/*
 
 import SwiftUI

 struct InvitePlaceRow2: View {
     
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
             RowCaption(label: .where)
                 .frame(height: InviteRowMetrics.primaryLineHeight)
                 .offset(y: contentOffset)
                 .shrinkPress { openMap() }
             chooseButton
         }
         .frame(height: rowHeight)
         .blurPop(visible: !ui.anyPopupOpenDelayed, scale: 1)
     }
 }

 extension InvitePlaceRow {
     
     
     //Shared by the value button and the "Where" caption beside it
     private func openMap() {
         withAnimation(.present) { ui.showMapView.toggle() }
     }

     private var chooseButton: some View {
         Button {
             openMap()
         } label: {
             HStack(spacing: InviteRowMetrics.valueChevronSpacing) {
                 valueSlot

                 DropDownButton(isOpen: ui.showMapView)
             }
             .offset(y: contentOffset)
             .frame(height: rowHeight)
         }
         .shrinkButton()
     }
     
     //Trailing-anchored slot: name+address and the placeholder blur-replace as one block on a
     //shared right edge, so the two never double-print and the address can't outlive the name.
     //The ZStack + .animation(value:) is the stable ancestor the .id swap needs.
     private var valueSlot: some View {
         ZStack(alignment: .trailing) {
             Group {
                 if let eventLocation {
                     locationNameAndAddress(eventLocation)
                 } else {
                     noLocationPlaceholder
                 }
             }
             .id(locationID)
             .transition(.blurReplace)
         }
         .frame(maxWidth: .infinity, alignment: .trailing)
         //Only a clear dissolves — nothing else nils the place, so picking or swapping one
         //stays on the plain content-swap curve.
         .animation(eventLocation == nil ? .dissolve : .transition, value: locationID)
     }

     //Keyed on the name so swapping one place for another dissolves too, not just clearing.
     private var locationID: String { eventLocation.flatMap(\.name) ?? "" }

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
 */

