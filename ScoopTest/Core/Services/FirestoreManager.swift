//
//  FirestoreManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

@Observable final class FirestoreManager: ProfileManaging {
    
    var userManager: UserManager?
    
    init(userManager: UserManager? = nil) {
        self.userManager = userManager
    }
    
    private let userCollection = Firestore.firestore().collection("users")
    
    
    private func userEventCollection (userId: String) -> CollectionReference {
        userCollection.document(userId).collection("user_events")
    }
    
    private func userEventDocument (userId: String, userEventId: String) -> DocumentReference {
        userEventCollection(userId: userId).document(userEventId)
    }
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createProfile (profile: UserProfile) async throws {
        try userDocument(userId: profile.userId).setData(from: profile, merge: false)
    }
    
    func getProfile(userId: String) async throws -> UserProfile {
        try await userDocument(userId: userId).getDocument(as: UserProfile.self)
    }
    
    func getProfile() async throws -> UserProfile {
        guard let id = userManager?.user?.userId else { throw URLError(.userAuthenticationRequired) }
        return try await getProfile(userId: id)
    }
    
    func update(userId: String, values: [UserProfile.CodingKeys: Any]) async throws {
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value }
        try await userDocument(userId: userId).updateData(data)
    }
    
    func update(values: [UserProfile.CodingKeys: Any]) async throws {
        guard let id = userManager?.user?.userId else { throw URLError(.userAuthenticationRequired) }
        try await update(userId: id, values: values)
    }
    
    func updatePrompt(userId: String, promptIndex: Int, prompt: PromptResponse) async throws {
        let key: UserProfile.CodingKeys
        switch promptIndex {
        case 1: key = .prompt1
        case 2: key = .prompt2
        case 3: key = .prompt3
        default: return
        }
        let data = try Firestore.Encoder().encode(prompt)
        try await update(userId: userId, values: [key: data])
    }
    
    func updatePrompt(promptIndex: Int, prompt: PromptResponse) async throws {
        guard let id = userManager?.user?.userId else { throw URLError(.userAuthenticationRequired) }
        try await updatePrompt(userId: id, promptIndex: promptIndex, prompt: prompt)
    }
    
    func addUserEvent(userId: String, matchId: String, event: Event, matchImageString: String, role: EdgeRole, matchName: String)  async throws {
        guard let eventId = event.id else { return }
        var data: [String: Any] = [
            UserEvent.CodingKeys.id.rawValue: eventId,
            UserEvent.CodingKeys.otherUserId.rawValue: matchId,
            UserEvent.CodingKeys.role.rawValue: role.rawValue,
            UserEvent.CodingKeys.status.rawValue: event.status.rawValue,
            UserEvent.CodingKeys.time.rawValue: event.time ?? Date(),
            UserEvent.CodingKeys.type.rawValue: event.type ?? "",
            UserEvent.CodingKeys.message.rawValue: event.message ?? "",
            UserEvent.CodingKeys.otherUserPhoto.rawValue: matchImageString,
            UserEvent.CodingKeys.otherUserName.rawValue: matchName,
            UserEvent.CodingKeys.updatedAt.rawValue: Date()
        ]
        let location = try Firestore.Encoder().encode(event.location)
        data[UserEvent.CodingKeys.place.rawValue] = location
        try await userEventCollection(userId: userId).document(eventId).setData(data)
    }
    
    func removeUserEvent(userId: String, userEventId: String) async throws {
        try await userEventDocument(userId: userId, userEventId: userEventId).delete()
    }

    func getAllUserEvents(userId: String) async throws -> [UserEvent] {
        try await userEventCollection(userId: userId).getDocuments(as: UserEvent.self)
    }

    
    func currentId() -> String {
        guard let id  = userManager?.user?.userId else {return ""}
        return id
    }
    
    enum EventScope { case upcomingInvited, upcomingAccepted, pastAccepted }
    
    private func eventsQuery(_ scope: EventScope, now: Date = .init()) -> Query {
        let plus3h = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        let uid = currentId()
        switch scope {
        case .upcomingInvited:
            return userEventCollection(userId: uid)
                .whereField(Event.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date: Date()))
                .whereField(UserEvent.CodingKeys.role.rawValue, isEqualTo: EdgeRole.received.rawValue)
                .order(by: Event.CodingKeys.time.stringValue)
        case .upcomingAccepted:
            return userEventCollection(userId: uid)
                .whereField(Event.CodingKeys.time.stringValue, isGreaterThan: Timestamp(date: plus3h))
                .whereField(UserEvent.CodingKeys.status.rawValue, isEqualTo: EventStatus.accepted.rawValue)
                .order(by: Event.CodingKeys.time.stringValue)
            
        case .pastAccepted:
            return userEventCollection(userId: uid)
                .whereField(Event.CodingKeys.status.stringValue, isEqualTo: EventStatus.accepted.rawValue)
                .whereField(Event.CodingKeys.time.stringValue, isLessThan: Timestamp(date: plus3h))
        }
    }
    
    private func getEvents(_ scope: EventScope, now: Date = .init()) async throws -> [UserEvent] {
        let query = eventsQuery(scope, now: now)
        return try await query
            .getDocuments(as: UserEvent.self)
    }
    
    func getUpcomingAcceptedEvents() async throws -> [UserEvent] {
        try await getEvents(.upcomingAccepted)
    }
    
    func getUpcomingInvitedEvents() async throws -> [UserEvent] {
        try await getEvents(.upcomingInvited)
    }

    func getPastAcceptedEvents() async throws -> [UserEvent] {
        try await getEvents(.pastAccepted)
    }
    
    
    //Need to update this, so that it is querying on the database, and only getting the right kind of user's.
    func getRandomProfile() async throws -> [UserProfile] {
        let snapshot = try await userCollection.getDocuments()
        let profiles = try snapshot.documents.compactMap { try $0.data(as: UserProfile.self)
        }
        return Array(profiles.shuffled().prefix(2))
    }
}




