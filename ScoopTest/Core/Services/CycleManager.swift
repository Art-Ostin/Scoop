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
    private var sessionManager: SessionManager
    
    init(cacheManager: CacheManaging, userManager: UserManager, sessionManager: SessionManager) {
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.sessionManager = sessionManager
    }
    
    private let users = Firestore.firestore().collection("users")
    private func cyclesCollection () -> CollectionReference {
        users.document(sessionManager.user.userId).collection("recommendation_cycles")
    }
    private func cycleDocument(cycleId: String) -> DocumentReference {
        cyclesCollection().document(cycleId)
    }
    private func recommendationsCollection (cycleId: String) -> CollectionReference {
        cycleDocument(cycleId: cycleId).collection("recommendations")
    }
    private func recommendationDocument(cycleId: String, profileId: String) -> DocumentReference {
        recommendationsCollection(cycleId: cycleId).document(profileId)
    }
    
    var cycleId: String? {
        sessionManager.activeCycle?.id
    }
    
    func fetchCycle(cycleId: String) async throws -> CycleModel {
        return try await cycleDocument(cycleId: cycleId).getDocument(as: CycleModel.self)
    }
    func fetchRecommendationItem(profileId: String) async throws -> RecommendationItem {
         if let cycleId {
            return try await recommendationDocument(cycleId: cycleId, profileId: profileId).getDocument(as: RecommendationItem.self)
        }
    }
    func fetchCycleProfiles() async throws -> [String] {
        if let cycleId {
            return try await recommendationsCollection(cycleId: cycleId)
                .whereField(RecommendationItem.CodingKeys.recommendationStatus.stringValue,
                            isEqualTo: RecommendationStatus.pending.rawValue)
                .getDocuments(as: RecommendationItem.self)
                .map(\.id)
        }
    }
    
    func createCycle() async throws {
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
        
        let docRef = try cyclesCollection().addDocument(from: cycle)
        let id = docRef.documentID
        try await createRecommendedProfiles(cycleId: id)
        try await userManager.updateUser(values: [UserProfile.CodingKeys.activeCycleId: id])
        await sessionManager.loadUser()
    }
    
    
    private func createRecommendedProfiles(cycleId: String) async throws {
        let snap = try await users.getDocuments()
        let ids = snap.documents.map( \.documentID ).filter { $0 != sessionManager.user.userId}
        let selectdIds = Array(ids.shuffled().prefix(4))
        
        for id in selectdIds {
            let newItem = RecommendationItem(id: id, profileViews: 0, recommendationStatus: .pending)
            try recommendationsCollection(cycleId: cycleId).addDocument(from: newItem)
        }
    }
    
    func updateCycle(key: String, field: Any) {
        if let cycleId {
            cycleDocument(cycleId: cycleId).updateData( [key: field] )
        }
    }
    func updateRecommendationItem(profileId: String, key: String, field: Any) {
        if let cycleId {
            recommendationDocument(cycleId: cycleId, profileId: profileId).updateData( [key: field] )
        }
    }
    
    func checkCycleStatus () async -> CycleStatus {
        guard let doc = sessionManager.activeCycle else { return .closed }
        if Date() > doc.endsAt.dateValue() {
            if doc.cycleStats.pending == 0 || Date() > doc.autoRemoveAt.dateValue() {
                try? await deleteCycle()
                return .closed
            } else {
                updateCycle(key: CycleModel.CodingKeys.cycleStatus.stringValue, field: CycleStatus.respond)
                return .respond
            }
        }
        return .active
    }
    
    func inviteSent(profileId: String) {
        guard var stats = sessionManager.activeCycle?.cycleStats else { return }
        stats .pending -= 1
        stats .invited += 1
        updateRecommendationItem(profileId: profileId, key: RecommendationItem.CodingKeys.recommendationStatus.stringValue, field: RecommendationStatus.invited.rawValue)
    }
    
    func deleteCycle() async throws {
        updateCycle(key: CycleModel.CodingKeys.cycleStatus.stringValue, field: CycleStatus.closed)
        try await userManager.updateUser(values: [UserProfile.CodingKeys.activeCycleId: FieldValue.delete()])
    }
    
}
