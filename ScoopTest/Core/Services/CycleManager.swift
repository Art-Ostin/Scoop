//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import FirebaseFirestore


@Observable final class CycleManager {
    
    //Configureation of WeeklyRecsManager
    @ObservationIgnored private let user: UserManager
    @ObservationIgnored private let profileManager: ProfileManaging
    @ObservationIgnored private var session: SessionManager?
    @ObservationIgnored private var cacheManager: CacheManaging
    
    init(user: UserManager, profileManager: ProfileManaging, cacheManager: CacheManaging,  session: SessionManager? = nil) {
        self.user = user
        self.profileManager = profileManager
        self.cacheManager = cacheManager
        self.session = session
    }
    
    
    func configure(session: SessionManager) {
        self.session = session
    }
    
    //UserId and the activeCycleId for editing and referencing
    private var currentUserId: String {
        user.user?.id ?? ""
    }
    private var activeCycleId: String {
        user.user?.activeCycleId ?? ""
    }
    
    
    //Document and collection Navigations
    
    private let users = Firestore.firestore().collection("users")
    
    private func cyclesCollection () -> CollectionReference {
        users.document(currentUserId).collection("recommendation_cycles")
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
    }
    private func createRecommendedProfiles(cycleId: String) async throws {
        let snap = try await users.getDocuments()
        let ids = snap.documents.map( \.documentID ).filter { $0 != currentUserId}
        let selectdIds = Array(ids.shuffled().prefix(4))
        
        for id in selectdIds {
            let newItem = RecommendationItem(id: id, profileViews: 0, recommendationStatus: .pending)
            try recommendationsCollection(cycleId: cycleId).addDocument(from: newItem)
        }
    }
    
    func fetchCycle() async throws -> RecommendationCycle {
        return try await cycleDocument(cycleId: activeCycleId).getDocument(as: RecommendationCycle.self)
    }
    func fetchRecommendationItem(profileId: String) async throws -> RecommendationItem {
        return try await recommendationDocument(cycleId: activeCycleId, profileId: profileId).getDocument(as: RecommendationItem.self)
    }
    
    
    
    //Gets all the shown Reccommendations, return eventInvite. Save the profile Images all to Cache immedietely. (BIG function)
    
    func fetchPendingCycleRecommendations() async throws -> [EventInvite] {
        let query = recommendationsCollection(cycleId: activeCycleId)
            .whereField(RecommendationItem.CodingKeys.recommendationStatus.stringValue, isEqualTo: RecommendationStatus.pending.rawValue)
        let ids = try await query.getDocuments(as: RecommendationItem.self).map(\.id)
        
        return await withTaskGroup(of: EventInvite?.self, returning: [EventInvite].self) { group in
            for id in ids {
                group.addTask {
                    guard let p = try? await self.profileManager.getProfile(userId: id) else { return nil }
                    let firstImage = try? await self.cacheManager.fetchFirstImage(profile: p)
                    return EventInvite(event: nil, profile: p, image: firstImage ?? UIImage())
                }
            }
            return await group.reduce(into: []) {result, element  in
                if let element {result.append(element)}
            }
        }
    }
    
    
    func updateCycle(key: String, field: Any) {
        cycleDocument(cycleId: activeCycleId).updateData( [key: field] )
    }
    func updateRecommendationItem(profileId: String, key: String, field: Any) {
        recommendationDocument(cycleId: activeCycleId, profileId: profileId).updateData( [key: field] )
    }
    
    //Functions requirred in App
    func deleteCycle() async throws {
        updateCycle(key: RecommendationCycle.CodingKeys.cycleStatus.stringValue, field: CycleStatus.closed)
        
        try await profileManager.update(values: [UserProfile.CodingKeys.activeCycleId: FieldValue.delete()])
    }
    
    func inviteSent(profileId: String) async throws {
        
        var stats = try await fetchCycle().cycleStats
        stats .pending -= 1
        stats .invited += 1
        
        let recItem = try await fetchRecommendationItem(profileId: profileId)
        updateRecommendationItem(profileId: profileId, key: RecommendationItem.CodingKeys.recommendationStatus.stringValue, field: RecommendationStatus.invited.rawValue)
        
    }
    
    func loadProfileRecsChecker () async throws -> Bool {
        guard user.user?.activeCycleId != nil else {return false}
        let doc = try await fetchCycle()
        let timeEnd = doc.endsAt.dateValue()
        let timeRefresh = doc.autoRemoveAt.dateValue()
        let profilesPending = doc.cycleStats.pending
        
        if Date() > timeEnd {
            if Date() > timeRefresh { try? await deleteCycle() ; return false }
            if profilesPending == 0 { try? await deleteCycle() ; return false }
        }
        return true
    }
    
    func showRespondToProfilesToRefresh() async throws -> Bool {
        let doc = try await fetchCycle()
        let timeEnd = doc.endsAt.dateValue()
        
        if Date() > timeEnd && doc.cycleStats.pending != 0 {
            return true
        }
        return false
    }
    
    
}

