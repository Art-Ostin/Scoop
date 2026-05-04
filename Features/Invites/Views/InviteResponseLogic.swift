//
//  InviteResponseLogic.swift
//  Scoop
//
//  Created by Art Ostin on 27/04/2026.
//

import SwiftUI

extension InvitesContainer {
    
    func respondToProfile(respondType: ProfileResponse, profileId: String) async throws {
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        ui.respondedToProfile = respondType
        try? await Task.sleep(for: .milliseconds(550))
        ui.selectedProfile = nil
        try await respondToProfileAction(respondType: respondType, profileId: profileId)
        try? await minDelay
        ui.respondedToProfile = nil
        if respondType == .accepted {
            selectedTab.wrappedValue = .events
        }
    }
    
    private func respondToProfileAction (respondType: ProfileResponse, profileId: String) async throws {
        switch respondType {
        case .accepted:
            try await acceptInvite(profileId: profileId)
        case .newTime:
            try await respondWithNewTime(profileId: profileId)
        case .newInvite:
            try await  respondWithEvent(profileId: profileId)
        case .decline:
            try await declineInvite(profileId: profileId)
        }
    }
        
    private func respondWithNewTime(profileId: String) async throws {
        if let newTime = vm.respondVMs[profileId]?.respondDraft.newTime {
            let rescheduleResponse = RescheduleResponse(eventId: newTime.event.id, userId: vm.userId, recipientId: newTime.event.otherUserId, oldTimes: newTime.event.proposedTimes, newTimes: newTime.proposedTimes)
                try await vm.sendNewTime(rescheduleResponse: rescheduleResponse)
        }
    }
    
    private func respondWithEvent(profileId: String) async throws {
        //1. From profileId, construct a eventResponse
        if let respondDraft = vm.respondVMs[profileId]?.respondDraft {
            let eventResponse = EventResponse(oldEvent: respondDraft.originalInvite.event, newEvent: respondDraft.newEvent, userId: vm.userId)
            try await vm.sendNewEvent(eventResponse: eventResponse)
        }
    }
    
    private func acceptInvite(profileId: String) async throws {
        if let originalInvite = vm.respondVMs[profileId]?.respondDraft.originalInvite, let selectedDay = originalInvite.selectedDay {
            try await vm.acceptInvite(eventId: originalInvite.event.id, senderId: originalInvite.event.otherUserId, acceptedDate: selectedDay)
        }
    }
    
    private func declineInvite(profileId: String) async throws {
        if let eventId = vm.respondVMs[profileId]?.respondDraft.originalInvite.event.id {
            try await vm.declineInvite(eventId: eventId, otherUserId: profileId)
        }
    }
}

