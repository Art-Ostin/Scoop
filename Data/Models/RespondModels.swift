//
//  EventRespondModels.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

enum ResponseType: Codable {
    case original, modified
}

struct RespondDraft: Codable  {
    
    var originalInvite: OriginalInvite
    var newTime: NewTimeDraft { didSet { respondType = .modified}}
    var newEvent: EventResponseDraft
    var respondMessage: String?
    var respondType: ResponseType
    
    init(event: UserEvent, userId: String) {
        let selectedDay = event.proposedTimes.firstAvailableDate
        self.originalInvite = OriginalInvite(event: event, selectedDay: selectedDay)
        self.newTime = NewTimeDraft(event: event, proposedTimes: .init())
        self.newEvent = EventResponseDraft(type: .drink, place: event.location)
        self.respondType = .original
    }
}

struct OriginalInvite: Codable {
    let event: UserEvent
    var selectedDay: Date?
}

struct NewTimeDraft: Codable {
    let event: UserEvent
    var proposedTimes: ProposedTimes
}




// MARK: - Persistable mirrors for UserDefaults

struct PersistableChatState: Codable {
    var unreadCount: Int
    var lastMessagePreview: String?
    var lastMessageAuthor: String?
    var lastMessageAt: Date?
}

struct PersistableUserEvent: Codable {
    var id: String?
    var otherUserId: String
    var otherUserName: String
    var otherUserPhoto: String
    var role: UserEvent.EdgeRole
    var type: Event.EventType
    var proposedTimes: ProposedTimes
    var acceptedTime: Date?
    var location: EventLocation
    var message: String?
    var status: Event.EventStatus
    var canText: Bool
    var chatState: PersistableChatState?
    var updatedAt: Date?
    var earlyTerminatorID: String?
}

struct PersistableOriginalInvite: Codable {
    var event: PersistableUserEvent
    var selectedDay: Date?
}

struct PersistableNewTimeDraft: Codable {
    var event: PersistableUserEvent
    var proposedTimes: ProposedTimes
}

struct PersistableRespondDraft: Codable {
    var originalInvite: PersistableOriginalInvite
    var newTime: PersistableNewTimeDraft
    var newEvent: EventDraft
    var respondMessage: String?
    var respondType: ResponseType
}

// MARK: - Conversions: domain → persistable

extension PersistableChatState {
    init(_ c: ChatState) {
        self.unreadCount = c.unreadCount
        self.lastMessagePreview = c.lastMessagePreview
        self.lastMessageAuthor = c.lastMessageAuthor
        self.lastMessageAt = c.lastMessageAt
    }
}

extension PersistableUserEvent {
    init(_ e: UserEvent) {
        self.id = e._id
        self.otherUserId = e.otherUserId
        self.otherUserName = e.otherUserName
        self.otherUserPhoto = e.otherUserPhoto
        self.role = e.role
        self.type = e.type
        self.proposedTimes = e.proposedTimes
        self.acceptedTime = e.acceptedTime
        self.location = e.location
        self.message = e.message
        self.status = e.status
        self.canText = e.canText
        self.chatState = e.chatState.map { PersistableChatState($0) }
        self.updatedAt = e.updatedAt
        self.earlyTerminatorID = e.earlyTerminatorID
    }
}

extension PersistableRespondDraft {
    init(_ d: RespondDraft) {
        self.originalInvite = PersistableOriginalInvite(
            event: PersistableUserEvent(d.originalInvite.event),
            selectedDay: d.originalInvite.selectedDay
        )
        self.newTime = PersistableNewTimeDraft(
            event: PersistableUserEvent(d.newTime.event),
            proposedTimes: d.newTime.proposedTimes
        )
        self.newEvent = d.newEvent
        self.respondMessage = d.respondMessage
        self.respondType = d.respondType
    }
}

// MARK: - Conversions: persistable → domain

extension ChatState {
    init(_ p: PersistableChatState) {
        self.init()
        self.unreadCount = p.unreadCount
        self.lastMessagePreview = p.lastMessagePreview
        self.lastMessageAuthor = p.lastMessageAuthor
        self.lastMessageAt = p.lastMessageAt
    }
}

extension UserEvent {
    init(_ p: PersistableUserEvent) {
        self.otherUserId = p.otherUserId
        self.otherUserName = p.otherUserName
        self.otherUserPhoto = p.otherUserPhoto
        self.role = p.role
        self.type = p.type
        self.proposedTimes = p.proposedTimes
        self.acceptedTime = p.acceptedTime
        self.location = p.location
        self.message = p.message
        self.status = p.status
        self.canText = p.canText
        self.chatState = p.chatState.map { ChatState($0) }
        self.updatedAt = p.updatedAt
        self.earlyTerminatorID = p.earlyTerminatorID
        self._id = p.id
    }
}

extension RespondDraft {
    init(_ p: PersistableRespondDraft) {
        self.originalInvite = OriginalInvite(
            event: UserEvent(p.originalInvite.event),
            selectedDay: p.originalInvite.selectedDay
        )
        self.newTime = NewTimeDraft(
            event: UserEvent(p.newTime.event),
            proposedTimes: p.newTime.proposedTimes
        )
        self.newEvent = p.newEvent
        self.respondMessage = p.respondMessage
        self.respondType = p.respondType
    }
}
