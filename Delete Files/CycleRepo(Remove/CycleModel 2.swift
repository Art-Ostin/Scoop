//
//  WeeklyRecModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
@preconcurrency import FirebaseFirestore

enum CycleStatus: String, Codable, Sendable { case active, closed, respond}


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
    var endsAt: Date
    var autoRemoveAt: Date
    
    enum Field: String {
        case id, startedAt, cycleStatus, cycleStats, profilesAdded, endsAt, autoRemoveAt
    }
}


