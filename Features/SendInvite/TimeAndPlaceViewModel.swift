//
//  TimeAndPlaceViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

@MainActor
@Observable
class TimeAndPlaceViewModel {
    
    let inviteModel: InviteModel
    let defaults: DefaultsManaging
    
    var event: EventFieldsDraft {
        didSet { updateEventDraft()}
    }
    
    init(inviteModel: InviteModel, defaults: DefaultsManaging) {
        self.inviteModel = inviteModel
        self.defaults = defaults
        self.event = Self.loadEvent(d: defaults, id: inviteModel.profileId)
    }
    
    private static func loadEvent(d: DefaultsManaging, id: String) -> EventFieldsDraft {
        if let storedEvent = d.fetchEventDraft(profileId: id) {
            return storedEvent
        } else {
            return EventFieldsDraft()
        }
    }
    
    func deleteEventDefault() {
        defaults.deleteEventDraft(profileId: inviteModel.profileId)
        event = EventFieldsDraft()
    }
    
    func updateEventDraft() {
        defaults.updateEventDraft(profileId: inviteModel.profileId, eventDraft: event)
    }
}


@Observable class TimeAndPlaceUIState {
    enum Popup { case type, time }
    var activePopup: Popup?
    var showMessageScreen: Bool = false
    var showMapView: Bool = false
    var isMessageTap: Bool = false
    var showInfoScreen: Bool = false
    let rowHeight: CGFloat = 50
    var showConfirmPopup: Bool = false

    func binding(for popup: Popup) -> Binding<Bool> {
        Binding(
            get: { self.activePopup == popup },
            set: { self.activePopup = $0 ? popup : nil }
        )
    }
}
