//
//  InvitesViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

@MainActor
@Observable class InvitesViewModel {

    let session: SessionManager
    let defaults: DefaultsManaging
    let imageLoader: ImageLoading
    let eventRepo: EventsRepository

    init(session: SessionManager, defaults: DefaultsManaging, imageLoader: ImageLoading, eventRepo: EventsRepository) {
        self.session = session
        self.defaults = defaults
        self.imageLoader = imageLoader
        self.eventRepo = eventRepo
    }
    
    var invites: [EventProfile] {session.invites}
    var userId: String {session.user.id}
    
    
    //Set up here -> I pass in an eventResponseDraft to the view, not an invite.
    var respondDrafts: [RespondDraft] {
        invites.map { invite in
            RespondDraft(event: invite.event, userId: session.user.id)
        }
    }
    
    func acceptInvite(eventProfile: EventProfile, acceptedTime: Date) async throws {
        var eventProfile = eventProfile
        eventProfile.event.acceptedTime = acceptedTime
        
        try await eventRepo.acceptEvent(eventId: eventProfile.id, acceptedDate: acceptedTime)
        var acceptedEvent = eventProfile.event
        acceptedEvent.acceptedTime = acceptedTime
        
        session.invites.removeAll { $0.id == eventProfile.id }
        session.events.append(eventProfile)
    }
    
    //For Defaults to update it
    func updateEventAcceptedTime(eventId: String, acceptedTime: Date) {
        
    }
    
    func loadImages(profile: UserProfile) async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile)
    }
}


@Observable final class RespondUIState {
    var showTimePopup: Bool = false
    var showMessageSection: Bool = false
    var showMeetInfo: Bool = false
    var showAddMessageScreen: Bool = false
    
    
    enum CardLayout {
        static let titleToTimeSpacing: CGFloat = 14.25
        static let timeToPlaceSpacing: CGFloat = 16.5
        static let actionTopSpacing: CGFloat = 25
        
        static let topPadding: CGFloat = 12
        static let bottomPadding: CGFloat = 10
    }
    
    enum PopupLayout {
        static let titleToTimeSpacing: CGFloat = 16 //12
        static let timeToPlaceSpacing: CGFloat = 20.5 //For Precise spacing
        static let actionTopSpacing: CGFloat = 26
        
        static let horizontalPadding: CGFloat = 22
        static let topPadding: CGFloat = 18
        static let bottomPadding: CGFloat = 18
        
        static func placeToMessageSpacing(hasResponseMessage: Bool) ->  CGFloat {
            hasResponseMessage ? 16 : 22
        }
    }
}







@Observable final class InvitesUIState {
    var selectedProfile: UserProfile? = nil
    var declineScreen: Bool? = false
    var acceptScreen: Bool = true
    var showDetails: Bool = false
    var showTimePopup: Bool = false
    var dismissOffset: CGFloat? = nil
}




