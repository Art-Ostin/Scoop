//
//  EventManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 03/08/2025.
//

import Foundation
import FirebaseFirestore


@Observable
class EventManager {
    
    @ObservationIgnored private let user: UserManager
    @ObservationIgnored private let profile: ProfileManaging
    
    init (user: UserManager, profile: ProfileManaging) {
        self.user = user
        self.profile = profile
    }
    
    private let eventCollection = Firestore.firestore().collection("events")
    
    private func eventDocument(id: String) -> DocumentReference {
        eventCollection.document(id)
    }
    
    func createEvent(event: Event) async throws {
        try eventDocument(id: event.id).setData(from: event)
    }
    
    func fetchEvent(eventId: String) async throws -> Event {
        try await eventDocument(id: eventId).getDocument(as: Event.self)
    }
    
    func updateTime(eventId: String, time: Date) async throws {
        let data: [String: Any] = [
            "time": time
        ]
        try await eventDocument(id: eventId).updateData(data)
    }
    
    
    func updateEvent(eventId: String, updateTo: Bool) async throws {
        let data: [String: Any] = [
            "accepted": updateTo
        ]
        try await eventDocument(id: eventId).updateData(data)
    }
    
    
    func getUserEvents ()  async throws  -> [Event] {
        guard let currentUser = user.user else {return []}
        let userId = currentUser.userId
        let snapshot = try await eventCollection.getDocuments()
        let events = snapshot.documents.compactMap { try? $0.data(as: Event.self) }
        return events
            .filter { $0.profile1_id == userId || $0.profile2_id == userId}
    }
    
    func getCurrentEvents () async throws -> [Event] {
        let events = try await getUserEvents()
        let now = Date()
        let currentEvents = events.filter {$0.time ?? Date() > now}
        let userCurrentEvents = currentEvents.filter {$0.status == .accepted}
        return userCurrentEvents
    }
    
    func getEventMatch(event: Event) async throws -> UserProfile {
        let userIds: [String] = [event.profile1_id, event.profile2_id].compactMap {$0}
        let currentUserId = user.user?.userId ?? ""
        guard let matchId = userIds.first(where: { $0 != currentUserId }) else {
            throw URLError(.badURL)
        }
        return try await profile.getProfile(userId: matchId)
    }
    
    func getFutureEvent () async throws -> [Event] {
        let events = try await getUserEvents()
        let now = Date()
        return events.filter {$0.time ?? Date() > now}
    }
    
    func getAcceptedEvents () async throws -> [Event] {
        let events = try await getUserEvents()
        return events.filter {$0.status == .accepted}
    }
    
    func getInvitedEvents () async throws -> [Event] {
        let events = try await getUserEvents()
        return events.filter {$0.status == .pending}
    }
}
