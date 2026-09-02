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
    
    //Injected
    let defaults: DefaultsManaging
    let session: Session
    let profile: UserProfile

    //Draft state (persisted to defaults on every edit)
    var respondDraft: RespondDraft {didSet {updateDefaults()}}
    
    
    init(invite: EventProfile , defaults: DefaultsManaging, session: Session) {
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
        guard var storedDraft = defaults.fetchRespondDraft(eventId: event.id) else {
            return RespondDraft(event: event, userId: profile.id)
        }
        storedDraft.rehydrate(with: event)   //the stored copy of the invite may be stale
        return storedDraft
    }
    
    private func deleteDraft() {
        respondDraft.newEvent = .init()
    }
}

@Observable final class RespondUIState {

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
}
