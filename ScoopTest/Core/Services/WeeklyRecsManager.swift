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
    @ObservationIgnored private let profile: ProfileManaging

    
    
    init(user: UserManager, profile: ProfileManaging) {
        self.user = user
        self.profile = profile
    }
    
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
            profilesAdded: ids.count,
            endsAt: Timestamp(date: endsAt),
            autoRemoveTime: Timestamp(date: autoRemove)
        )
        let docRef = try weeklyCycleCollection().addDocument(from: cycle)
        let weeklyCycleId = docRef.documentID
        try await setWeeklyItems(weeklyCycleId: weeklyCycleId)
    }
    
    func getWeeklyRecDoc(_ user:UserProfile? = nil) async throws -> WeeklyRecCycle {
        guard let id = (user?.weeklyRecsId ?? self.user.user?.weeklyRecsId) else { throw URLError(.badServerResponse)}
        return try await weeklyRecDocument(weeklyCycleId: id).getDocument(as: WeeklyRecCycle.self)
    }
    
    
    
    
    func updateWeeklyRecDoc(field: String, to value: Any) async throws {
        guard
            let user = user.user,
            let id = user.weeklyRecsId
        else { return }
        try await weeklyRecDocument(weeklyCycleId: id).updateData([field: value])
    }

    
    func deleteWeeklyRec() async throws {
        try await updateWeeklyRecDoc(field: "cycleStatus", to: CycleStatus.closed)
        try await profile.update(values: [UserProfile.CodingKeys.weeklyRecsId: FieldValue.delete()])
    }
        
    
    func getWeeklyItems(weeklyCycleId: String) async throws -> [String?] {
        let collectionRef = weeklyCycleItemsCollection (weeklyCycleId: weeklyCycleId)
        let weeklyItems = try await collectionRef.getDocuments(as: WeeklyRecItem.self)
        return  weeklyItems.map {$0.id}
    }
}




//let query = weeklyCycleCollection()
//    .whereField("cycleStatus", isEqualTo: CycleStatus.active)
//let snap = try await query.getDocuments()
//for doc in snap.documents {
//    try await doc.reference.updateData([
//        "cycleStatus": CycleStatus.closed
//    ])
//}


