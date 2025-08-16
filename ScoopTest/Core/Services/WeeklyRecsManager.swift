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
    
    private func weeklyCycleItemsCollection (weeklyCycleId: String) -> CollectionReference {
        weeklyRecDocument(weeklyCycleId: weeklyCycleId).collection("items")
    }
    
    private func weeklyRecDocument (weeklyCycleId: String) -> DocumentReference {
        weeklyCycleCollection().document(weeklyCycleId)
    }
    
    private func weeklyRecItemDocument(weeklyCycleId: String, profileId: String) -> DocumentReference {
        weeklyCycleItemsCollection(weeklyCycleId: weeklyCycleId).document(profileId)
    }
    
        
    private func setWeeklyProfileRecs() async throws -> [String] {
        let snap = try await userCollection.getDocuments()
        let ids = snap.documents
            .map(\.documentID)
            .filter { $0 != currentId }
        return Array(ids.shuffled().prefix(4))
    }
    private func setWeeklyItems(weeklyCycleId: String) async throws {
        let ids = try await setWeeklyProfileRecs()
        for id in ids {
            let item = WeeklyRecItem(id: id, profileViews: 0, itemStatus: .pending, addedDay: nil, actedAt: nil)
            try weeklyRecItemDocument(weeklyCycleId: weeklyCycleId, profileId: id).setData(from: item)
        }
    }
    func setWeeklyRecs() async throws {
        let ids = try await setWeeklyProfileRecs()
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let autoRemove = Calendar.current.date(byAdding: .day, value: 21, to: now)!
        let cycle = WeeklyRecCycle(
            id: nil,
            startedAt: nil,
            cycleStatus: .active,
            cycleStats: .init(total: ids.count, invited: 0, dismissed: 0, pending: ids.count),
            dailyProfilesAdded: 0,
            endsAt: Timestamp(date: endsAt),
            autoRemoveTime: Timestamp(date: autoRemove)
        )
        
        let docRef = try weeklyCycleCollection().addDocument(from: cycle)
        let weeklyCycleId = docRef.documentID
        try await setWeeklyItems(weeklyCycleId: weeklyCycleId)
    }
    
    
}




