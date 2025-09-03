//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation

enum UserEventUpdate {
    case eventInvite(userEvent: UserEvent)
    case removeInvite(userEvent: UserEvent)
    case eventAccepted(userEvent: UserEvent)
    case pastEventAccepted(userEvent: UserEvent)
}


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
        
        let initiatorUserEvent = makeUserEvent(profile: user, role: .sent, event: event)
        let recipientUserEvent = makeUserEvent(profile: profile, role: .received, event: event)
        
        try fs.set(userEventPath(userId: user.id, userEventId: id), value: initiatorUserEvent)
        try fs.set(userEventPath(userId: profile.id, userEventId: id), value: recipientUserEvent)
        
        func makeUserEvent(profile: UserProfile, role: EdgeRole, event: Event) -> UserEvent  {
            UserEvent(otherUserId: profile.id, role: role, status: event.status, time: event.time, type: event.type, message: event.message, place: event.location, otherUserName: profile.name , otherUserPhoto: profile.imagePathURL.first ?? "", updatedAt: nil, inviteExpiryTime: event.inviteExpiryTime)
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
        inv.map { .eventInvite(userEvent: $0) }
        + upc.map { .eventAccepted(userEvent: $0) }
        + pas.map { .pastEventAccepted(userEvent: $0) }
        
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
                                continuation.yield(.eventInvite(userEvent: e))
                            } else if e.status == .accepted {
                                if e.time >= plus6h {
                                    continuation.yield(.eventAccepted(userEvent: e))
                                } else {
                                    continuation.yield(.pastEventAccepted(userEvent: e))
                                }
                            } else {
                                continuation.yield(.removeInvite(userEvent: e))
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
        fs.update(userEventPath(userId: initiatorId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        fs.update(userEventPath(userId: recipientId, userEventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
        fs.update(EventPath(eventId: eventId), fields: [Event.Field.status.rawValue: newStatus.rawValue])
    }
}









/*
 private func filtersForScope(_ scope: EventScope) -> ([FSWhere], FSOrder?) {
     let plus6h = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
     typealias F = UserEvent.Field
     switch scope {
     case .upcomingInvited:
         return ([
             FSWhere(field: F.status.rawValue, op: .eq,  value: EventStatus.pending.rawValue),
             FSWhere(field: F.role.rawValue,   op: .eq,  value: EdgeRole.received.rawValue),
         ], FSOrder(field: F.time.rawValue, descending: false))
         
     case .upcomingAccepted:
         return ([
             
             FSWhere(field: F.status.rawValue, op: .eq,  value: EventStatus.accepted.rawValue),
             FSWhere(field: F.time.rawValue,   op: .gte, value: plus6h),
         ], FSOrder(field: F.time.rawValue, descending: false))
         
     case .pastAccepted:
         return ([
             FSWhere(field: F.status.rawValue, op: .eq, value: EventStatus.accepted.rawValue),
             FSWhere(field: F.time.rawValue,   op: .lt, value: plus6h),
         ], FSOrder(field: F.time.rawValue, descending: true))
     }
 }

 */

/*
 func eventStream(userId: String) -> AsyncThrowingStream<UserEventUpdate, Error> {
     AsyncThrowingStream { continuation in
         let reg = userEventCollection(userId: userId).addSnapshotListener { snapshot, error in
             if let error = error { continuation.finish(throwing: error) ; return }
             guard let snap = snapshot else { return }
             
             for change in snap.documentChanges {
                 switch change.type {

                 case .modified, .added:
                     guard let ue = try? change.document.data(as: UserEvent.self) else { continue }
                     switch ue.status {
                     case .pending: if ue.role == .received { continuation.yield(.eventInvite(userEvent: ue))}
                     case .accepted: continuation.yield(.eventAccepted(userEvent: ue))
                     case .pastAccepted: continuation.yield(.pastEventAccepted(userEvent: ue))
                     default : continuation.yield(.removeInvite(id: ue.otherUserId))
                     }
                 case .removed:
                     break
                 }
             }
         }
         continuation.onTermination = { _ in reg.remove() }
     }
 }
 */


//extension Query {
//    func getDocuments<T>(as: T.Type) async throws -> [T] where T: Decodable {
//        let snapshot = try await self.getDocuments()
//        return try snapshot.documents.map { try $0.data(as: T.self)}
//    }
//}



//
//private func userEventCollection (userId: String) -> CollectionReference {
//    userCollection.document(userId).collection("user_events")
//}


/*
 private func eventsQuery(_ scope: EventScope, userId: String) throws -> Query {
     let plus3h = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
     switch scope {
     case .upcomingInvited:
         fs.get(userEvents(userId: userId, value)) -> [UserEvent]
         
         return userEventCollection(userId: userId)
             .whereField(UserEvent.Field.time.rawValue, isGreaterThan: Timestamp(date: Date()))
             .whereField(UserEvent.Field.role.rawValue, isEqualTo: EdgeRole.received.rawValue)
             .whereField(UserEvent.Field.status.rawValue, isEqualTo: EventStatus.pending.rawValue)
             .order(by: Event.Field.time.rawValue)
     case .upcomingAccepted:
         return userEventCollection(userId: userId)
             .whereField(UserEvent.Field.time.rawValue, isGreaterThan: Timestamp(date: plus3h))
             .whereField(UserEvent.Field.status.rawValue, isEqualTo: EventStatus.accepted.rawValue)
             .order(by: Event.Field.time.rawValue)
         
     case .pastAccepted:
         return userEventCollection(userId: userId)
             .whereField(UserEvent.Field.status.rawValue, isEqualTo: EventStatus.accepted.rawValue)
             .whereField(UserEvent.Field.time.rawValue, isLessThan: Timestamp(date: plus3h))
     }
 }
 
 private func getEvents(_ scope: EventScope, now: Date = .init(), userId: String) async throws -> [UserEvent] {
     let query = try eventsQuery(scope, now: now, userId: userId)
     return try await query
         .getDocuments(as: UserEvent.self)
 }
 
 func getUpcomingAcceptedEvents(userId: String) async throws -> [UserEvent] {
     try await getEvents(.upcomingAccepted, userId: userId)
 }
 
 func getUpcomingInvitedEvents(userId: String) async throws -> [UserEvent] {
     try await getEvents(.upcomingInvited, userId: userId)
 }
 
 func getPastAcceptedEvents(userId: String) async throws -> [UserEvent] {
     try await getEvents(.pastAccepted, userId: userId)
 }
 */
/*
 
 func fetchUserEvents(_ scope: EventScope, userId: String, now: Date = .init()) async throws -> [UserEvent] {
     let path = "users/\(userId)/user_events"
     let F = UserEvent.Field.self
     let plus6h = Calendar.current.date(byAdding: .hour, value: 6, to: now)!
     
     let (filters, order): ([FSWhere], FSOrder?) = {
         switch scope {
         case .upcomingInvited:
             return (
                 [
                     FSWhere(field: F.time.rawValue,   op: .gt, value: now),
                     FSWhere(field: F.role.rawValue,   op: .eq, value: EdgeRole.received.rawValue),
                     FSWhere(field: F.status.rawValue, op: .eq, value: EventStatus.pending.rawValue)
                 ],
                 FSOrder(field: F.time.rawValue, descending: false)
             )
         case .upcomingAccepted:
             return (
                 [
                     FSWhere(field: F.time.rawValue, op: .gt, value: plus6h),
                     FSWhere(field: F.status.rawValue, op: .eq, value: EventStatus.accepted.rawValue)
                 ],
                 FSOrder(field: F.time.rawValue, descending: false)
             )
         case .pastAccepted:
             return (
             [
                 FSWhere(field: F.status.rawValue, op: .eq, value: EventStatus.accepted.rawValue),
                 FSWhere(field: F.time.rawValue, op: .lt, value: plus6h)
             ],
             FSOrder(field: F.time.rawValue, descending: true)
         )
         }
     }()
     return try await fs.queryCollection(path, filters: filters, orderBy: order, limit: nil)
 }
 */
