//
//  RespondViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

@MainActor
@Observable
class RespondViewModel {
    
    let image: UIImage
    
    let defaults: DefaultsManaging
    let sessionManager: SessionManager
    let user: UserProfile
    
    var respondDraft: RespondDraft {
        didSet {updateDefaults()}
    }
    
    var responseType: ResponseType {respondDraft.respondType}
    
    init(image: UIImage, user: UserProfile, defaults: DefaultsManaging, sessionManager: SessionManager, event: UserEvent) {
        self.image = image
        self.user = user
        self.defaults = defaults
        self.sessionManager = sessionManager
        self.respondDraft = Self.loadRespondDraft(defaults: defaults, profile: user, event: event, currentUserId: sessionManager.user.id)
    }
        
    @MainActor func deleteEventDefault() {
        let profileId = respondDraft.originalInvite.event.otherUserId
        defaults.deleteEventDraft(profileId: profileId)
        respondDraft.newEvent = EventDraft(initiatorId: sessionManager.user.id, recipientId: profileId)
    }    
    
    private func updateDefaults() {
        defaults.updateRespondDraft(profileId: user.id, respondDraft: respondDraft)
    }
    
    private static func loadRespondDraft(defaults: DefaultsManaging, profile: UserProfile, event: UserEvent, currentUserId: String) -> RespondDraft {
        if let storedDraft = defaults.fetchRespondDraft(profileId: profile.id) {
            print("Fetched Response Draft")
            return storedDraft
        } else {
            print("Created new Response Draft")
            return RespondDraft(event: event, userId: profile.id)
        }
    }
}

@Observable final class RespondUIState {
    
    enum Tab {
        case message, event, details
    }

    var showTimePopup: Bool = false
    var showMessageSection: Bool = false
    var showMessageScreen: Bool = false
    var showMeetInfo: Bool = false
    
    func hasEventMessage(_ respondDraft: RespondDraft) -> Bool {
        respondDraft.originalInvite.event.message?.isEmpty == false
    }
    
    func hasRespondMessage(_ respondDraft: RespondDraft) -> Bool {
        respondDraft.respondMessage?.isEmpty == false
    }
    
    func hasBothMessages(_ respondDraft: RespondDraft) -> Bool {
        return hasEventMessage(respondDraft) && hasRespondMessage(respondDraft)
    }
    
    enum CardLayout {
        static let titleToTimeSpacing: CGFloat = 9.25
        static let timeToPlaceSpacing: CGFloat = 11.5
        static let actionTopSpacing: CGFloat = 20
        
        static let topPadding: CGFloat = 9
        static let bottomPadding: CGFloat = 12
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


