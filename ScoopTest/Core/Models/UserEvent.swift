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
    let other_user_id: String
    let role: EdgeRole
    let status: EventStatus
    let event_time: Date
    let event_type: String
    let event_message: String?
    let event_place: EventLocation?
    let other_user_name: String?
    let other_user_photo: URL
    let updated_at: Date?
    
    
    enum CodingKeys: CodingKey {
        case id
        case other_user_id
        case role
        case status
        case event_time
        case event_type
        case event_message
        case event_place
        case other_user_name
        case other_user_photo
        case updated_at
    }
}

