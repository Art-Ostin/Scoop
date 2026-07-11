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
    let inviteModel: InviteContext
    let defaults: DefaultsManaging

    //Draft state (persisted to defaults on every edit)
    var event: EventFieldsDraft {
        didSet { updateEventDraft()}
    }
    
    init(inviteModel: InviteContext, defaults: DefaultsManaging) {
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

    enum Popup: Equatable { case type, time }

    ///Track if the time or type popup is open on the screen
    var activePopup: Popup?
    private(set) var delayedPopup: Popup?
    var showMessageScreen: Bool = false
    var showMapView: Bool = false
    var showInfoScreen: Bool = false
    var messageLineCount: Int = 0

    ///Check a specific popup, or whether any popup is open when called with no argument.
    func isPopupOpen(_ popup: Popup? = nil) -> Bool {
        popup == nil ? activePopup != nil : popup == activePopup
    }
    func isPopupOpenDelayed(_ popup: Popup? = nil) -> Bool {
        popup == nil ? delayedPopup != nil : popup == delayedPopup
    }
    
    func syncDelayedPopup() async {
        let target = activePopup
        try? await Task.sleep(for: .milliseconds(target == nil ? 40 : 150))
        guard !Task.isCancelled else { return }   // sleep's error was swallowed; don't commit a stale value
        delayedPopup = target
    }
    
    func binding(for popup: Popup) -> Binding<Bool> {
        Binding(
            get: { self.activePopup == popup },
            set: { self.activePopup = $0 ? popup : nil }
        )
    }
}
