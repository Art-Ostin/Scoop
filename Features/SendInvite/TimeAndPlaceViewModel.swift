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
    
    //Injected
    let profileId: String
    let defaults: DefaultsManaging

    //Draft state (persisted to defaults on every edit)
    var event: EventFields {
        didSet { updateEventDraft()}
    }
    
    init(profileId: String, defaults: DefaultsManaging) {
        self.profileId = profileId
        self.defaults = defaults
        self.event = Self.loadEvent(d: defaults, id: profileId)
    }
    
    private static func loadEvent(d: DefaultsManaging, id: String) -> EventFields {
        if let storedEvent = d.fetchEventDraft(profileId: id) {
            return storedEvent
        } else {
            return EventFields()
        }
    }
    
    func deleteEventDefault() {
        defaults.deleteEventDraft(profileId: profileId)
        event = EventFields()
    }
    
    func updateEventDraft() {
        defaults.updateEventDraft(profileId: profileId, eventDraft: event)
    }
}


@Observable class TimeAndPlaceUIState {

    enum Popup: Equatable { case type, time }

    ///Track if the time or type popup is open on the screen
    var activePopup: Popup?
    private(set) var delayedPopup: Popup?
    private(set) var delayedTimePopupOpen = false
    
    //Different views open
    var showMapView: Bool = false
    var showInfoScreen: Bool = false
    var showMessageScreen: Bool = false
    var showConfirmScreen: Bool? = false
    
    ///Check a specific popup, or whether any popup is open when called with no argument.
    func isPopupOpen(_ popup: Popup? = nil) -> Bool {
        popup == nil ? activePopup != nil : popup == activePopup
    }
    
    func isPopupOpenDelayed(_ popup: Popup? = nil) -> Bool {
        popup == nil ? delayedPopup != nil : popup == delayedPopup
    }
    
    
    func syncDelayedPopups() async {
        async let popup: Void = syncDelayedPopup()
        async let timePopup: Void = syncDelayedTimePopup()

        _ = await (popup, timePopup)
    }
    
    private func syncDelayedPopup() async {
        let target = activePopup
        try? await Task.sleep(for: .milliseconds(target == nil ? 40 : 50))
        guard !Task.isCancelled else { return }   // sleep's error was swallowed; don't commit a stale value
        delayedPopup = target
    }

    private func syncDelayedTimePopup() async {
        let target = activePopup == .time
        try? await Task.sleep(for: .milliseconds(target ? 120 : 40))
        guard !Task.isCancelled else { return }
        delayedTimePopupOpen = target
    }
}
