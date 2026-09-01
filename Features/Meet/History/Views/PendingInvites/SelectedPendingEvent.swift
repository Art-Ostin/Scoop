//
//  SelectedPendingEvent.swift
//  Scoop
//
//  Created by Art Ostin on 29/08/2026.
//

import SwiftUI

struct SelectedPendingEvent: View {

    //Injected
    let eventProfile: EventProfile
    let images: [UIImage]

    let rowHeight: CGFloat = 33
    
    @Binding var openEventInfo: EventProfile?

    //Local view state
    @State private var flight: PendingFlightChoreo
    @State private var prepared: [UIImage] = []
    @State private var scrollProgress: Double = 0
    @State private var containerTop: CGFloat = 0 //This view's global origin — the stationary chevron's slot arrives in global space

    init(eventProfile: EventProfile, images: [UIImage], sourceRect: CGRect, glassRing: CGFloat,
         openEventInfo: Binding<EventProfile?>,
         onClosing: @escaping () -> Void,
         onChromeReturn: @escaping () -> Void,
         onClosed: @escaping () -> Void
    ) {
        self.eventProfile = eventProfile
        self.images = images
        self._openEventInfo = openEventInfo
        _flight = State(initialValue: PendingFlightChoreo(source: sourceRect, glassRing: glassRing,
                                                          onClosing: onClosing,
                                                          onChromeReturn: onChromeReturn,
                                                          onClosed: onClosed))
    }
    
    var body: some View {
        ZStack {
            inviteBackdrop
                .opacity(flight.backdropOpacity)

            VStack(spacing: Spacing.xl) {
                selectedEvent
                BottomBackButton(visible: false) { }
            }
            .offset(flight.cardOffset)
            .simultaneousGesture(flight.dismissDrag)
        }
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { containerTop = $0 }
        .overlay(alignment: .top) { stationaryBackButton }
        .task { await prepareImages() }
        .task { await flight.bakeCoverBand(photo: coverPhoto) }
        .onDisappear { flight.unmounted() }
    }
}

extension SelectedPendingEvent {

    private var selectedEvent: some View {
        VStack(spacing: 0) {
            imagePager
            
            detailsRow
        }
        .background(Color.white)
        .modifier(flight.morph(photo: coverPhoto, title: inviteTitle))
        .shadow(.card, strength: flight.shadowStrength) //After the mask, so it wears the window's shape
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight.reportCard($0) }
        .padding(.horizontal, Spacing.gutter) //The card is a full-bleed surface, not a text column
    }

    private var imagePager: some View {
        Color.clear
            .aspectRatio(AspectRatio.pendingEvent.ratio, contentMode: .fit)
            .overlay {
                if flight.settled {
                    InviteCarousel(images: prepared.isEmpty ? images : prepared,
                                   ratio: AspectRatio.pendingEvent.ratio,
                                   blursBottom: true,
                                   scrollProgress: $scrollProgress)
                        .overlay(alignment: .bottomLeading) { profileName }
                        .scrollDisabled(flight.dragEngaged) //An engaged dismiss drag freezes the pager's own axis
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { flight.reportPagerBand($0) }
    }

    private func prepareImages() async {
        var ready: [UIImage] = []
        for image in images {
            ready.append(await image.byPreparingForDisplay() ?? image)
        }
        prepared = ready
    }

    private var coverPhoto: UIImage { eventProfile.image ?? images.first ?? UIImage() }

    private var inviteTitle: String { "Invited \(eventProfile.profile.name)" }
    
    private var detailsRow: some View {
        let e = eventProfile.event
        
        return EventTypeTimeAndPlace(
            type: e.type,
            message: e.message,
            time: e.proposedTimes,
            place: e.location,
            openInfo: {openEventInfo = eventProfile}
        )
    }
    
    private var profileName: some View {
        Text(inviteTitle)
            .font(.title(22)) //The invite card's title type — "Invite <name>" reads the same here
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .padding(.horizontal, 20) //Geometry: the invite card's own title inset from the artwork edge
            .padding(.bottom, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inviteBackdrop: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(Color.white.opacity(0.1))
            .ignoresSafeArea()
            .onTapGesture { flight.close() }
    }
    
    @ViewBuilder
    private var stationaryBackButton: some View {
        if flight.hasChevronSlot {
            BottomBackButton(visible: flight.chevronVisible) { flight.close() }
                .offset(y: flight.chevronSlotY - containerTop)
        }
    }
}


/*
 
 private var rowRule: some View {
     VeryLightDivider()
         .padding(.leading, 40)
 }
 
 private var detailRows: some View {
     let e = eventProfile.event
     
     return VStack(alignment: .leading, spacing: 19) {
         EventTypeRow(type: e.type, message: e.message, openEventInfo: { openEventInfo = eventProfile})
         rowRule
         EventTimeRow(time: eventProfile.event.proposedTimes)
         rowRule
         EventPlaceRow(location: eventProfile.event.location)
     }
     .padding(.horizontal, Spacing.lg)
     .padding(.top, 20)
     .padding(.bottom, Spacing.lg)
 }

 
 private let iconColumn: CGFloat = 20

 private let iconGap = Spacing.lg - 4

 private let textColumn = iconColumn + iconGap

 private extension View {
     func detailIconColumn() -> some View {
         frame(width: iconColumn)
     }
 }





 private var placeRow: some View {
     let location = eventProfile.event.location
     return HStack(spacing: iconGap) {
         Image(.eventMapIcon)
             .scaleEffect(1.2)
             .detailIconColumn()

         Text(location.name ?? "View Venue")
             .font(.body(16, .bold))
     }
     .frame(height: rowHeight)
     .frame(maxWidth: .infinity, alignment: .leading)
 }
 private var typeRow: some View {
     HStack(spacing: iconGap) {
         
         Text(eventProfile.event.type.emoji)
             .font(.body(16, .bold))
             .detailIconColumn()

         VStack(alignment: .leading, spacing: 6) {
             eventAndInfo
             
             if let message = eventProfile.event.message {
                 text(message: message)
             }
         }
     }
     .frame(minHeight: rowHeight) //Grows past the one-line row box when a message is present
     .frame(maxWidth: .infinity, alignment: .leading)
 }

 
 private var eventAndInfo: some View {
     Button {
         openEventInfo = eventProfile
     } label: {
         HStack(alignment: .top, spacing: 4) {
             Text(eventProfile.event.type.longTitle)
                 .font(.body(16, .bold))
             
             Image(systemName: "info.circle")
                 .foregroundStyle(Color.textTertiary)
                 .font(.body(11, .medium))
                 .offset(y: -2)
         }
     }
     .growButton()
 }
 
 private func text(message: String) -> some View {
     Text(message)
         .font(.body(14, .regularItalic))
         .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
         .lineLimitAndShrink(3)
         .frame(maxWidth: .infinity, alignment: .leading)
         .fixedSize(horizontal: false, vertical: true)
 }

 */
