//
//  WeeklyRecModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
@preconcurrency import FirebaseFirestore


enum CycleStatus: Codable, Sendable { case active, closed }
enum RecommendationStatus: String, Codable, Sendable { case pending, invited, dismiss, accepted }

struct CycleStats: Codable, Sendable {
    var total: Int
    var invited: Int
    var accepted: Int
    var dismissed: Int
    var pending: Int
}


struct CycleModel: Identifiable, Codable, Sendable{
    @DocumentID var id: String?
    @ServerTimestamp var startedAt: Timestamp?
    var cycleStatus: CycleStatus = .active
    var cycleStats: CycleStats
    var profilesAdded: Int
    var endsAt: Timestamp 
    var autoRemoveAt: Timestamp
    
    enum CodingKeys: CodingKey {
        case id
        case startedAt
        case cycleStatus
        case cycleStats
        case profilesAdded
        case endsAt
        case autoRemoveAt
    }
}

struct RecommendationItem: Identifiable, Codable, Sendable{
    var id: String // = profileId
    var profileViews: Int
    var recommendationStatus: RecommendationStatus
    @ServerTimestamp var addedDay: Timestamp?
    var actedAt: Timestamp?
    
    enum CodingKeys: CodingKey {
        case id
        case profileViews
        case recommendationStatus
        case addedDay
        case actedAt
    }
}


