//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation

enum UserEventKind { case invite, accepted, pastAccepted, remove }
typealias UserEventUpdate = (event: UserEvent, kind: UserEventKind)

class EventManager {
    
    private let userManager: UserManager
    private let fs: FirestoreService
    
    init(userManager: UserManager, fs: FirestoreService) { self.userManager = userManager ; self.fs = fs }
    
    private func EventPath(eventId: String) -> String {
        "events/\(eventId)"
    }
    
    private func userEventPath(userId: String, userEventId: String) -> String {
        return "users/\(userId)/user_events/\(userEventId)"
    }
    
    private func fetchEvent(eventId: String) async throws -> Event {
        try await fs.get(EventPath(eventId: eventId))
    }
    
    private func fetchUserEvent(userId: String, userEventId: String) async throws -> UserEvent {
        try await fs.get(userEventPath(userId: userId, userEventId: userEventId))
    }
    
    func createEvent(draft: EventDraft, user: UserProfile, profile: UserProfile) async throws {
        var draft = draft
        
        draft.initiatorId = user.id
        draft.recipientId = profile.id
        draft.inviteExpiryTime = getEventExpiryTime(draft: draft)
        
        let event = Event(draft: draft)
        let id = try fs.add("events", value: event)
        
        let initiatorUserEvent = makeUserEvent(otherProfile: profile, role: .sent, event: event)
        let recipientUserEvent = makeUserEvent(otherProfile: user, role: .received, event: event)
        
        try fs.set(userEventPath(userId: user.id, userEventId: id), value: initiatorUserEvent)
        try fs.set(userEventPath(userId: profile.id, userEventId: id), value: recipientUserEvent)
        
        func makeUserEvent(otherProfile: UserProfile, role: EdgeRole, event: Event) -> UserEvent  {
            UserEvent(otherUserId: otherProfile.id, role: role, status: event.status, time: event.time, type: event.type, message: event.message, place: event.location, otherUserName: otherProfile.name , otherUserPhoto: otherProfile.imagePathURL.first ?? "", updatedAt: nil, inviteExpiryTime: event.inviteExpiryTime)
        }
    }
    
    func getEventExpiryTime(draft: EventDraft) -> Date? {
        guard let eventTime = draft.time else {return nil}
        
        let timeUntilEvent = eventTime.timeIntervalSince(Date())
        
        let day: TimeInterval = 24*3600
        let hour: TimeInterval = 3600
        
        if  timeUntilEvent > TimeInterval(2*day + 8*hour) {
            return Date().addingTimeInterval(2 * day)
        } else if  timeUntilEvent > TimeInterval(day + 8*hour) {
            return Date().addingTimeInterval(day)
        } else if timeUntilEvent > TimeInterval(14*hour)  {
            return Calendar.current.date(byAdding: .hour, value: -6, to: eventTime)
        } else if timeUntilEvent > TimeInterval(8*hour) {
            return Calendar.current.date(byAdding: .hour, value: -1, to: eventTime)
        } else {
            return eventTime
        }
    }
    
    func eventTracker(userId: String, now: Date = .init()) async throws -> (initial: [UserEventUpdate], updates: AsyncThrowingStream<UserEventUpdate, Error>) {
        let path = "users/\(userId)/user_events"
        let plus6h = Calendar.current.date(byAdding: .hour, value: 6, to: now)!
        typealias F = UserEvent.Field
        
        let invitedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq,  value: EventStatus.pending.rawValue),
            FSWhere(field: F.role.rawValue,   op: .eq,  value: EdgeRole.received.rawValue),
        ]
        
        let upcomingAcceptedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq,  value: EventStatus.accepted.rawValue),
            FSWhere(field: F.time.rawValue,   op: .gte, value: plus6h),
        ]
        
        let pastAcceptedFilters: [FSWhere] = [
            FSWhere(field: F.status.rawValue, op: .eq, value: EventStatus.accepted.rawValue),
            FSWhere(field: F.time.rawValue,   op: .lt, value: plus6h),
        ]
        
        async let invited: [UserEvent] = fs.fetchFromCollection(path, filters: invitedFilters, orderBy: FSOrder(field: F.time.rawValue, descending: false), limit: nil)
        
        async let upcoming: [UserEvent] = fs.fetchFromCollection(path, filters: upcomingAcceptedFilters, orderBy: FSOrder(field: F.time.rawValue, descending: false), limit: nil)
        
        async let past: [UserEvent] = fs.fetchFromCollection(path, filters: pastAcceptedFilters, orderBy: FSOrder(field: F.time.rawValue, descending: true), limit: nil)
        
        let (inv, upc, pas) = try await (invited, upcoming, past)
        
        let initial: [UserEventUpdate] =
            inv.map { (event: $0, kind: .invite) }
          + upc.map { (event: $0, kind: .accepted) }
          + pas.map { (event: $0, kind: .pastAccepted) }
        
        let base: AsyncThrowingStream<FSCollectionEvent<UserEvent>, Error> = fs.streamCollection(path, filters: [], orderBy: nil, limit: nil)
        
        let updates = AsyncThrowingStream<UserEventUpdate, Error> { continuation in
            Task {
                do {
                    for try await ev in base {
                        switch ev {
                        case .initial:
                            continue
                        case .added(let it), .modified(let it):
                            let e = it.model
                            if e.status == .pending, e.role == .received, now < e.inviteExpiryTime {
                                continuation.yield((event: e, kind: .invite))
                            } else if e.status == .accepted {
                                if e.time >= plus6h {
                                    continuation.yield((event: e, kind: .accepted))
                                } else {
                                    continuation.yield((event: e, kind: .pastAccepted))
                                }
                            } else {
                                continuation.yield((event: e, kind: .remove))
                            }
                        case .removed:
                            break
                        }
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
        }
        return (initial, updates)
    }
    
    func updateStatus(eventId: String, to newStatus: EventStatus) async throws {
        let event = try await fetchEvent(eventId: eventId), initiatorId = event.initiatorId, recipientId = event.recipientId
        try await fs.update(userEventPath(userId: initiatorId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        try await fs.update(userEventPath(userId: recipientId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        try await fs.update(EventPath(eventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
    }    
}
