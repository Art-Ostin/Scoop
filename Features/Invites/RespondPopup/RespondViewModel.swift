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
    
    var respondDraft: RespondDraft {
        didSet {updateDefaults()}
    }
    
    
    
    
    func updateDraftTime() {
        
    }
    
    func accept() {
        
    }
    
    func acceptWithNewTime() {
        
    }
    
    func sendNewInvite() {
        
    }
    
    func decline () {
        
    }
    

    
    
    @MainActor func deleteEventDefault() {
        let profileId = respondDraft.event.otherUserId
        defaults.deleteEventDraft(profileId: profileId)
        respondDraft.eventDraft = EventDraft(initiatorId: sessionManager.user.id, recipientId: profileId, type: .drink)
    }
    
    private func updateDefaults() {
        
    }
}
