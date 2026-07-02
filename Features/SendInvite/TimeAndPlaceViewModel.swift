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
    
    let inviteModel: InviteContext
    let defaults: DefaultsManaging
    
    
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


/*
 //Drive certain behaviour is popup open
 var typePopupOpen: Bool = false
 var timePopupOpen: Bool = false
 var typePopupOpenDelayed: Bool = false
 var timePopupOpenDelayed: Bool = false
 let rowHeight: CGFloat = 50
 var showConfirmPopup: Bool = false
 var isMessageTap: Bool = false
 */


@Observable class TimeAndPlaceUIState {
    
    //1. Logic to deal with the popup open
    enum Popup: Equatable { case type, time }
    
    ///Track if the time or type popup is open on the screen
    var activePopup: Popup?
    private(set) var delayedPopup: Popup?
    
    ///Convenienve functions to check if the type open or not
    func isPopupOpen(_ popup: Popup? = nil) -> Bool { popup == activePopup }
    func isPopopOpenDelayed(_ popup: Popup? = nil) -> Bool {popup == delayedPopup}
    
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
        
    var showMessageScreen: Bool = false
    var showMapView: Bool = false
    var showInfoScreen: Bool = false
    var messageLineCount: Int = 0
}
