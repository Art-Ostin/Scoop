//
//  ProfileRecModel.swift
//  Scoop
//
//  Created by Art Ostin on 14/02/2026.
//

import Foundation
@preconcurrency import FirebaseFirestore

//Data type stored in Firebase for Profile Recommendations
struct ProfileRec: Identifiable, Codable, Sendable{
    
    enum Field: String {
        case id, profileViews, status, addedDay, updatedDay
    }
    
    enum Status: String, Codable, Sendable {
        case pending, invited, declined, invitedDeclined, invitedAccepted
    }
    
    @DocumentID var id: String?
    var profileViews: Int
    var status: Status
    @ServerTimestamp var addedDay: Timestamp?
    var updatedDay: Timestamp?
}
