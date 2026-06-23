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
    
    var image: UIImage
    let defaults: DefaultsManaging
    let session: Session
    let profile: UserProfile
    
    var respondDraft: RespondDraft {
        didSet {updateDefaults()}
    }
    
    var responseType: ResponseType {respondDraft.respondType}
    
    init(image: UIImage, invite: EventProfile , defaults: DefaultsManaging, session: Session) {
        self.image = image
        self.profile = invite.profile
        self.defaults = defaults
        self.session = session
        self.respondDraft = Self.loadRespondDraft(defaults: defaults, profile: invite.profile, event: invite.event, currentUserId: session.user.id)
    }

        
    @MainActor func deleteEventDefault() {
        let profileId = respondDraft.originalInvite.event.otherUserId
        defaults.deleteEventDraft(profileId: profileId)
        respondDraft.newEvent = EventFieldsDraft(type: .drink)
    }
    
    private func updateDefaults() {
        defaults.updateRespondDraft(eventId: respondDraft.originalInvite.event.id, respondDraft: respondDraft)
    }
    
    private static func loadRespondDraft(defaults: DefaultsManaging, profile: UserProfile, event: UserEvent, currentUserId: String) -> RespondDraft {
        if let storedDraft = defaults.fetchRespondDraft(eventId: event.id) {
            return storedDraft
        } else {
            return RespondDraft(event: event, userId: profile.id)
        }
    }
}

@Observable final class NewRespondUIState {
    
    //1. Determine if 0, 1 or 2 messages
    func hasEventMessage(_ respondDraft: RespondDraft) -> Bool {
        respondDraft.originalInvite.event.message?.isEmpty == false
    }
    
    func hasRespondMessage(_ respondDraft: RespondDraft) -> Bool {
        respondDraft.respondMessage?.isEmpty == false
    }

    func hasBothMessages(_ respondDraft: RespondDraft) -> Bool {
        return hasEventMessage(respondDraft) && hasRespondMessage(respondDraft)
    }
    
    var showMeetInfo: Bool = false
}


@Observable
class RespondPopupUIState {
    //Hide the popup when dismissing the screen
    var dismissHidePopup: Bool = false

    //Logic for which Popup to show
    var confirmNewTimeInvite: Bool = false
    var confirmAcceptInvite: Bool = false
    var popupShown: Bool { confirmNewTimeInvite || confirmAcceptInvite }
    //Track the scroll Position
    var scrollPosition: RespondScrollType? = .acceptPage
}


enum RespondPopupInfo {
    case newInvite, acceptInvite, sendNewTimes

    var title: String {
        switch self {
            case .newInvite: return "Event Commitment"
            case .acceptInvite: return "Event Commitment"
            case .sendNewTimes: return "New Times Proposed"
        }
    }
    var cancel: String {"Cancel"}
    var understand: String {"I Understand"}
    
    func message(dates: [Date] = [], placeName: String = "") -> String {
        switch self {
        case .newInvite: return "If they accept & you don't show, you'll be blocked from Scoop"
        case .acceptInvite: return "You are committing to meeting on x. If you don't show, you'll be blocked from Scoop"
        case .sendNewTimes: return "If they accept one of your proposed times & you don't show, you'll be blocked from Scoop"
        }
    }
}

