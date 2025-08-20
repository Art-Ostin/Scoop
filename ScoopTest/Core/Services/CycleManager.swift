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
        
    //Functions to Create/Fetch and update the cycle documents and reccomendation documents
    func createCycle() async throws {
        let addedCount = 4
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let autoRemoveAt = Calendar.current.date(byAdding: .day, value: 21, to: now)!
        
        let cycle = RecommendationCycle(
            cycleStats: .init(total: addedCount, invited: 0, accepted: 0, dismissed: 0, pending: addedCount),
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
    var cycleId: String? {
        sessionManager.activeCycleId
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
    
    func fetchCycle() async -> RecommendationCycle {
        do {
            if let cycleId {
                return try await cycleDocument(cycleId: cycleId).getDocument(as: RecommendationCycle.self)
            }
        } catch { print(error)}
    }
    
    
    func fetchRecommendationItem(profileId: String) async throws -> RecommendationItem {
        if let cycleId {
            return try await recommendationDocument(cycleId: cycleId, profileId: profileId).getDocument(as: RecommendationItem.self)
        }
    }
    
    func fetchPendingCycleRecommendations() async throws -> [ProfileModel] {
        if let cycleId {
            let ids = try await recommendationsCollection(cycleId: cycleId)
                .whereField(RecommendationItem.CodingKeys.recommendationStatus.stringValue,
                            isEqualTo: RecommendationStatus.pending.rawValue)
                .getDocuments(as: RecommendationItem.self)
                .map(\.id)
            let data = ids.map { (id: $0, event: nil as UserEvent?) }
            return await inviteLoader(data: data)
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
    
    
    //Functions requirred in App
    func deleteCycle() async throws {
        updateCycle(key: RecommendationCycle.CodingKeys.cycleStatus.stringValue, field: CycleStatus.closed)
        
        try await userManager.updateUser(values: [UserProfile.CodingKeys.activeCycleId: FieldValue.delete()])
    }
    func inviteSent(profileId: String) async throws {
        var stats = await fetchCycle().cycleStats
        stats .pending -= 1
        stats .invited += 1
        
        updateRecommendationItem(profileId: profileId, key: RecommendationItem.CodingKeys.recommendationStatus.stringValue, field: RecommendationStatus.invited.rawValue)
    }
    
    func checkCycleSatus () async -> Bool {
        guard (cycleId != nil) else { return false }
        let doc = await fetchCycle()
        let timeEnd = doc.endsAt.dateValue()
        let timeRefresh = doc.autoRemoveAt.dateValue()
        let profilesPending = doc.cycleStats.pending
        
        if Date() > timeEnd {
            if Date() > timeRefresh { try? await deleteCycle() ; return false }
            if profilesPending == 0 { try? await deleteCycle() ; return false }
        }
        return true
    }
    
    func showRespondToProfilesToRefresh() async -> Bool {
        let doc = await fetchCycle()
        let timeEnd = doc.endsAt.dateValue()
        
        if Date() > timeEnd && doc.cycleStats.pending != 0 {
            return true
        }
        return false
    }
    
    func inviteLoader(data: [(id: String, event: UserEvent?)]) async -> [ProfileModel] {
        return await withTaskGroup(of: ProfileModel?.self, returning: [ProfileModel].self) { group in
            for item in data {
                group.addTask {
                    guard let profile = try? await self.userManager.fetchUser(userId: item.id) else { return nil }
                    let image = try? await self.cacheManager.fetchFirstImage(profile: profile)
                    return ProfileModel(event: item.event, profile: profile, image: image ?? UIImage())
                }
            }
            return await group.reduce(into: []) {result, element  in
                if let element {result.append(element)}
            }
        }
    }
}
