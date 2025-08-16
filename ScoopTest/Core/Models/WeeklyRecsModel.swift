//
//  WeeklyRecModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
@preconcurrency import FirebaseFirestore


enum CycleStatus: Codable, Sendable { case active, closed }
enum ItemStatus: Codable, Sendable { case pending, invited, dismiss }

struct CycleStats: Codable, Sendable {
    var total: Int
    var invited: Int
    var dismissed: Int
    var pending: Int
}

struct WeeklyRecCycle: Identifiable, Codable, Sendable{
    @DocumentID var id: String?
    @ServerTimestamp var startedAt: Timestamp?
    var cycleStatus: CycleStatus
    var cycleStats: CycleStats
    var dailyProfilesAdded: Int
    var endsAt: Timestamp
    var autoRemoveTime: Timestamp
}


struct WeeklyRecItem: Identifiable, Codable, Sendable{
    @DocumentID var id: String? // = profileId
    var profileViews: Int
    var itemStatus: ItemStatus
    var addedDay: Int?
    @ServerTimestamp var actedAt: Timestamp?
}


