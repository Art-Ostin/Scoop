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
    @ObservationIgnored private let session: SessionManager

    
    init(user: UserManager, profile: ProfileManaging, session: SessionManager) {
        self.user = user
        self.profile = profile
        self.session = session
    }
    
    private var currentId: String {
        user.user?.id ?? ""
    }
    
    private var weeklyRecDoc: String? {
        user.user?.weeklyRecsId
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
        if let id = weeklyRecDoc {
            try await weeklyRecDocument(weeklyCycleId: id).updateData([field: value])
        }
    }
    

    
    func deleteWeeklyRec() async throws {
        try await updateWeeklyRecDoc(field: "cycleStatus", to: CycleStatus.closed)
        try await profile.update(values: [UserProfile.CodingKeys.weeklyRecsId: FieldValue.delete()])
    }
        
    
    func getWeeklyItems() async throws -> [WeeklyRecItem] {
        guard let id = weeklyRecDoc else {return []}
        let collectionRef = weeklyCycleItemsCollection (weeklyCycleId: id)
        let items = try await collectionRef.getDocuments(as: WeeklyRecItem.self)
        return items
    }

    
    func updateForInviteSent(profileId: String) async throws {
        var stats = try await getWeeklyRecDoc().cycleStats
        stats.pending -= 1
        stats.invited += 1
        
        let items = try await getWeeklyItems()
        
        if var weeklyItem = items.first(where: { $0.id == profileId}) {
            weeklyItem.itemStatus = .invited
        }
        session.removeProfileRec(profileId: profileId)
    }
}

