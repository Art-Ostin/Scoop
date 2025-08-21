//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import FirebaseFirestore


final class CycleManager {
    
    private var cacheManager: CacheManaging
    private var userManager: UserManager
    
    init(cacheManager: CacheManaging, userManager: UserManager) {
        self.cacheManager = cacheManager
        self.userManager = userManager
    }

    private let users = Firestore.firestore().collection("users")
    
    private func cycleCollection(userId: String) -> CollectionReference {
        users.document(userId).collection("recommendation_cycles")
    }
    
    private func cycleDocument(userId: String, cycleId: String) -> DocumentReference {
        cycleCollection(userId: userId).document(cycleId)
    }

    private func profilesCollection (userId: String, cycleId: String) -> CollectionReference {
        cycleDocument(userId: userId, cycleId: cycleId).collection("recommendations")
    }
    
    private func profileDocument (userId: String, cycleId: String, profileId: String) -> DocumentReference {
        profilesCollection(userId: userId, cycleId: cycleId).document(profileId)
    }
    
    func fetchCycle(userId: String, cycleId: String) async throws -> CycleModel {
        return try await cycleDocument(userId: userId, cycleId: cycleId).getDocument(as: CycleModel.self)
    }
    
    func fetchProfileItem(userId: String, cycleId: String, profileId: String) async throws -> RecommendationItem {
        return try await profileDocument(userId: userId, cycleId: cycleId, profileId: profileId).getDocument(as: RecommendationItem.self)
    }
    
    func fetchCycleProfiles (userId: String, cycleId: String) async throws -> [String] {
        return try await profilesCollection(userId: userId, cycleId: cycleId)
            .whereField(RecommendationItem.CodingKeys.recommendationStatus.stringValue, isEqualTo: RecommendationStatus.pending.rawValue)
            .getDocuments(as: RecommendationItem.self)
            .map(\.id)
    }
    
    
    @discardableResult
    func createCycle(userId: String) async throws -> String {
        let addedCount = 4
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let autoRemoveAt = Calendar.current.date(byAdding: .day, value: 21, to: now)!
        
        let cycle = CycleModel(
            cycleStats: CycleStats(total: addedCount, invited: 0, accepted: 0, dismissed: 0, pending: addedCount),
            profilesAdded: addedCount,
            endsAt: Timestamp(date: endsAt),
            autoRemoveAt: Timestamp(date: autoRemoveAt)
        )
        
        let docRef = try cycleCollection(userId: userId).addDocument(from: cycle)
        let id = docRef.documentID
        try await createRecommendedProfiles(userId: userId, cycleId: id)
        try await userManager.updateUser(values: [UserProfile.CodingKeys.activeCycleId: id])
        return id
    }
    
    private func createRecommendedProfiles(userId: String, cycleId: String) async throws {
        let snap = try await users.getDocuments()
        let ids = snap.documents.map( \.documentID ).filter { $0 != userId}
        let selectdIds = Array(ids.shuffled().prefix(4))
                
        for id in selectdIds {
            let newItem = RecommendationItem(id: id, profileViews: 0, recommendationStatus: .pending)
            try profileDocument(userId: userId, cycleId: cycleId, profileId: id).setData(from: newItem)
        }
    }

    func updateCycle(userId: String, cycleId: String, key: String, field: Any) {
        cycleDocument(userId: userId, cycleId: cycleId).updateData([key: field])
    }
    
    func updateProfileItem(userId: String, cycleId: String, profileId: String, key: String, field: Any) {
        profileDocument(userId: userId, cycleId: cycleId, profileId: profileId).updateData([key: field])
    }
    
    
    func checkCycleStatus (userId: String, cycle: CycleModel?) async -> CycleStatus {
        guard let cycle, let id = cycle.id else  {
            print("returned here")
            return .closed }
        print("Got to this stage")
        if Date() > cycle.endsAt.dateValue() {
            if cycle.cycleStats.pending == 0 || Date() > cycle.autoRemoveAt.dateValue() {
                try? await deleteCycle(userId: userId, cycleId: id)
                return .closed
            } else {
                updateCycle(userId: userId, cycleId: id, key: CycleModel.CodingKeys.cycleStatus.stringValue, field: CycleStatus.respond)
                return .respond
            }
        }
        print("returned active here")
        return .active
    }
    
    func inviteSent(userId: String, cycle: CycleModel?, profileId: String) {
        guard let cycleId = cycle?.id else { return }
        updateProfileItem(userId: userId, cycleId: cycleId, profileId: profileId, key: RecommendationItem.CodingKeys.recommendationStatus.stringValue, field: RecommendationStatus.invited.rawValue)
    }
        
    func deleteCycle(userId: String, cycleId: String) async throws {
        updateCycle(userId: userId, cycleId: cycleId, key: CycleModel.CodingKeys.cycleStatus.stringValue, field: CycleStatus.closed)
        try await userManager.updateUser(values: [UserProfile.CodingKeys.activeCycleId: FieldValue.delete()])
    }
}
