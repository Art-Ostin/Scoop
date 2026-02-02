//
//  ProfileInvite.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/08/2025.
//

import Foundation
@preconcurrency import FirebaseFirestore

struct ProfileModel: Identifiable, Equatable, Hashable {
    var event: UserEvent?
    var profile: UserProfile
    var image: UIImage?
    var id: String { profile.id}
    
    static func == (lhs: ProfileModel, rhs: ProfileModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


struct ProfileRec: Identifiable, Codable, Sendable{
    @DocumentID var id: String?
    var profileViews: Int
    var status: Status
    @ServerTimestamp var addedDay: Timestamp?
    var actedAt: Timestamp?
    
    enum Field: String {
        case id, profileViews, status, addedDay
    }
    
    enum Status: String, Codable, Sendable {
        case pending, invited, declined, invitedDeclined, invitedAccepted
    }
}
