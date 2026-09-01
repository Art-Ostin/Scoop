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
        EventImagePager(
            isSettled: flight.settled,
            dragEngaged: flight.dragEngaged,
            title: "Invited \(eventProfile.profile.name)",
            images: prepared.isEmpty ? images : prepared,
        )
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
