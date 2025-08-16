//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import FirebaseFirestore


@Observable final class WeeklyRecsManager {
    
    @ObservationIgnored private let user: UserManager
    
    init(user: UserManager) { self.user = user}
    
    private var currentId: String {
        user.user?.id ?? ""
    }
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func weeklyCycleCollection () -> CollectionReference {
        userCollection.document(currentId).collection("weekly_cycle_recs")
    }
    
    private func weeklyRecDocument (weeklyCycleId: String) -> DocumentReference {
        weeklyCycleCollection().document(weeklyCycleId)
    }
    
    private func weeklyCycleItemsCollection (weeklyCycleId: String) -> CollectionReference {
        weeklyRecDocument(weeklyCycleId: weeklyCycleId).collection("items")
    }
    
    private func weeklyRecItemDocument(weeklyCycleId: String, profileId: String) -> DocumentReference {
        weeklyCycleItemsCollection(weeklyCycleId: weeklyCycleId).document(profileId)
    }
    
    
    
    
    func createWeeklyRecs() async throws {
        
        let data: [String: Any] = [
            
            "
            
        ]
    }
    
}

//struct WeeklyRecCycle: Identifiable, Codable, Sendable{
//    @DocumentID var id: String?
//    @ServerTimestamp var startedAt: Timestamp?
//    var cycleStatus: CycleStatus
//    var cycleStats: CycleStats
//    var dailyProfilesAdded: Int
//    var endsAt: Timestamp
//    var autoRemoveTime: Timestamp
//}



