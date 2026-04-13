//
//  RespondViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

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
    
    init(image: UIImage, user: UserProfile, defaults: DefaultsManaging, sessionManager: SessionManager, respondDraft: RespondDraft) {
        self.image = image
        self.user = user
        self.defaults = defaults
        self.sessionManager = sessionManager
        self.respondDraft = respondDraft
    }
    
    func updateDraftTime() {
        
    }
    
    @MainActor func deleteEventDefault() {
        let profileId = respondDraft.originalInvite.event.otherUserId
        defaults.deleteEventDraft(profileId: profileId)
        respondDraft.newEvent = EventDraft(initiatorId: sessionManager.user.id, recipientId: profileId)
    }
    
    private func updateDefaults() {
        
    }
}

@Observable final class RespondUIState {
    var showTimePopup: Bool = false
    var showMessageSection: Bool = false
    var showMeetInfo: Bool = false
    var showMessageScreen: Bool = false
    
    func hasEventMessage(_ respondDraft: RespondDraft) -> Bool {
        respondDraft.originalInvite.event.message != nil
    }
    
    func hasRespondMessage(_ respondDraft: RespondDraft) -> Bool {
        respondDraft.respondMessage?.isEmpty != false
    }
    
    func hasBothMessages(_ respondDraft: RespondDraft) -> Bool {
        return hasEventMessage(respondDraft) && hasRespondMessage(respondDraft)
    }
    
    enum CardLayout {
        static let titleToTimeSpacing: CGFloat = 12.25
        static let timeToPlaceSpacing: CGFloat = 14.5
        static let actionTopSpacing: CGFloat = 23
        
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

