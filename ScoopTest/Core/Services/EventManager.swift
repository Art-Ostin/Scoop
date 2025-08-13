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
        //Create the event with some default Values
        let doc = eventCollection.document()
        var e = event
        e.initiatorId = currentId()
        e.id = doc.documentID
        e.date_created = Date()
        try doc.setData(from: e)
        
        //Create UserEvent
        let recipientProfile = try await profile.getProfile(userId: event.recipientId ?? "")
        let recipientName = recipientProfile.name ?? ""
        let recipientImageString = recipientProfile.imagePathURL?.first ?? ""
        
        let inviteeProfile = user.user
        let inviteeName = inviteeProfile?.name ?? ""
        let inviteeImageString = inviteeProfile?.imagePathURL?.first ?? ""
        Task {
            try? await profile.addUserEvent(userId: currentId(), matchId: recipientProfile.id, event: e,
                                            matchImageString: recipientImageString, role: .sent, matchName: recipientName)
            try? await profile.addUserEvent(userId: recipientProfile.id, matchId: currentId(), event: e,
                                            matchImageString: inviteeImageString, role: .received, matchName: inviteeName)
        }
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
    
    func updateStatus(eventId: String, updateTo: EventStatus) async throws {
        let data: [String: Any] = [Event.CodingKeys.status.stringValue : updateTo.rawValue]
        try await eventDocument(id: eventId).updateData(data)
    }
    
    private func currentId() -> String {
        guard let uid = user.user?.userId else { return ""}
        return uid
    }
}

extension Query {
    func getDocuments<T>(as: T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { try $0.data(as: T.self)}
    }
}
