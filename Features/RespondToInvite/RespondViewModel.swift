//
//  RespondViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI


@Observable
class RespondPopupUIState {
    //Hide the popup when dismissing the screen
    var dismissHidePopup: Bool = false
    
    //showTimePopup
    var showTimePopup: Bool = false

    //Logic for which Popup to show
    var confirmNewTimeInvite: Bool = false
    var confirmAcceptInvite: Bool = false
    var confirmSendNewInvite: Bool = false
    var popupShown: Bool { confirmNewTimeInvite || confirmAcceptInvite || confirmSendNewInvite}
    
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
        case .newInvite: return "If they accept one of your proposed times & you don't show, you'll be blocked from Scoop"
        case .acceptInvite: return "You are committing to meeting on x. If you don't show, you'll be blocked from Scoop"
        case .sendNewTimes: return "If they accept one of your proposed times & you don't show, you'll be blocked from Scoop"
        }
    }
}


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
        respondDraft.newEvent = EventFieldsDraft(type: .drink)
    }
    
    private func updateDefaults() {
        defaults.updateRespondDraft(eventId: user.id, respondDraft: respondDraft)
    }
    
    private static func loadRespondDraft(defaults: DefaultsManaging, profile: UserProfile, event: UserEvent, currentUserId: String) -> RespondDraft {
        if let storedDraft = defaults.fetchRespondDraft(eventId: event.id) {
            return storedDraft
        } else {
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


