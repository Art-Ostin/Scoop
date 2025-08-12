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
    let time: Date?
    let type: String?
    let message: String?
    let place: EventLocation?
    let otherUserName: String?
    let otherUserPhoto: String?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case otherUserId = "other_user_id"
        case role = "role"
        case status = "status"
        case time = "time"
        case type = "type"
        case message = "message"
        case place = "place"
        case otherUserName = "other_user_name"
        case otherUserPhoto = "other_user_photo"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(DocumentID<String>.self, forKey: .id)
        self.otherUserId = try container.decode(String.self, forKey: .otherUserId)
        self.role = try container.decode(EdgeRole.self, forKey: .role)
        self.status = try container.decode(EventStatus.self, forKey: .status)
        self.time = try container.decodeIfPresent(Date.self, forKey: .time)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.place = try container.decodeIfPresent(EventLocation.self, forKey: .place)
        self.otherUserName = try container.decodeIfPresent(String.self, forKey: .otherUserName)
        self.otherUserPhoto = try container.decodeIfPresent(String.self, forKey: .otherUserPhoto)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self._id, forKey: .id)
        try container.encode(self.otherUserId, forKey: .otherUserId)
        try container.encode(self.role, forKey: .role)
        try container.encode(self.status, forKey: .status)
        try container.encodeIfPresent(self.time, forKey: .time)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.message, forKey: .message)
        try container.encodeIfPresent(self.place, forKey: .place)
        try container.encodeIfPresent(self.otherUserName, forKey: .otherUserName)
        try container.encodeIfPresent(self.otherUserPhoto, forKey: .otherUserPhoto)
        try container.encodeIfPresent(self.updatedAt, forKey: .updatedAt)
    }
}

