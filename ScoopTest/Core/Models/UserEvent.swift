//
//  EdgeEvents.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

import Foundation
import FirebaseFirestore


enum EdgeRole: String, Codable { case sent, received }


struct UserEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let otherUserId: String
    
    let role: EdgeRole
    let status: EventStatus

    let eventTime: Date
    let eventType: String
    let eventMessage: String?
    let eventPlace: EventLocation?
    let otherUserPhoto: URL
    let updatedAt: Date?
    
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.otherUserId, forKey: .otherUserId)
        try container.encode(self.role, forKey: .role)
        try container.encode(self.status, forKey: .status)
        try container.encode(self.eventTime, forKey: .eventTime)
        try container.encode(self.eventType, forKey: .eventType)
        try container.encodeIfPresent(self.eventMessage, forKey: .eventMessage)
        try container.encodeIfPresent(self.eventPlace, forKey: .eventPlace)
        try container.encode(self.otherUserPhoto, forKey: .otherUserPhoto)
        try container.encodeIfPresent(self.updatedAt, forKey: .updatedAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case otherUserId = "other_user_id"
        case role = "role"
        case status = "status"
        case eventTime = "event_time"
        case eventType = "event_type"
        case eventMessage = "event_message"
        case eventPlace = "event_place"
        case otherUserPhoto = "other_user_photo"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.otherUserId = try container.decode(String.self, forKey: .otherUserId)
        self.role = try container.decode(EdgeRole.self, forKey: .role)
        self.status = try container.decode(EventStatus.self, forKey: .status)
        self.eventTime = try container.decode(Date.self, forKey: .eventTime)
        self.eventType = try container.decode(String.self, forKey: .eventType)
        self.eventMessage = try container.decodeIfPresent(String.self, forKey: .eventMessage)
        self.eventPlace = try container.decodeIfPresent(EventLocation.self, forKey: .eventPlace)
        self.otherUserPhoto = try container.decode(URL.self, forKey: .otherUserPhoto)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}
