//
//  WeeklyRecModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
@preconcurrency import FirebaseFirestore


enum CycleStatus: String, Codable, Sendable { case active, closed, respond}

enum ProfileRecStatus: String, Codable, Sendable { case pending, invited, dismiss, accepted }

struct CycleStats: Codable, Sendable {
    var total: Int
    var invited: Int
    var accepted: Int
    var dismissed: Int
    var pending: Int
    
    enum CodingKeys: CodingKey {
        case total, invited, accepted, dismissed, pending
    }
}


struct CycleModel: Identifiable, Codable, Sendable{
    @DocumentID var id: String?
    @ServerTimestamp var startedAt: Timestamp?
    var cycleStatus: CycleStatus = .active
    var cycleStats: CycleStats
    var profilesAdded: Int
    var endsAt: Timestamp 
    var autoRemoveAt: Timestamp
    
    enum Field: String {
        case id, startedAt, cycleStatus, cycleStats, profilesAdded, endsAt, autoRemoveAt
    }
}


struct ProfileRec: Identifiable, Codable, Sendable{
    var id: String // = profileId
    var profileViews: Int
    var status: ProfileRecStatus
    @ServerTimestamp var addedDay: Timestamp?
    var actedAt: Timestamp?
    
    enum Field: String {
        case id, profileViews, status, addedDay
    }
}
