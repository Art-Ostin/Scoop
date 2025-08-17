//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import FirebaseFirestore


@Observable final class WeeklyRecsManager {
    
    //Configureation of WeeklyRecsManager
    @ObservationIgnored private let user: UserManager
    @ObservationIgnored private let profileManager: ProfileManaging
    @ObservationIgnored private var session: SessionManager?
    @ObservationIgnored private var cacheManager: CacheManaging?
    
    init(user: UserManager, profileManager: ProfileManaging, session: SessionManager? = nil, cacheManager: CacheManaging) {
        self.user = user
        self.profileManager = profileManager
        self.cacheManager = cacheManager
        self.session = session
    }
    func configure(session: SessionManager) {
        self.session = session
    }
    
    
    //UserId and the activeCycleId for editing and referencing
    private var currentUserId: String? {
        user.user?.id
    }
    private var activeCycleId: String? {
        user.user?.activeCycleId
    }
    
    
    //Document and collection Navigations
    
    private let users = Firestore.firestore().collection("users")
    
    private func cyclesCollection () -> CollectionReference {
        if  let id = currentUserId {
            users.document(id).collection("recommendation_cycles")
        }
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
        let ids = snap.documents.map( \.documentID ).filter { $0 != currentUserId! }
        let selectdIds = Array(ids.shuffled().prefix(4))
        
        for id in selectdIds {
            let newItem = RecommendationItem(id: id, profileViews: 0, recommendationStatus: .pending)
            try recommendationsCollection(cycleId: cycleId).addDocument(from: newItem)
        }
    }
    
    func fetchCycle() async throws -> RecommendationCycle {
        if let id = activeCycleId {
            return try await cycleDocument(cycleId: id).getDocument(as: RecommendationCycle.self)
        }
    }
    func fetchRecommendationItem(profileId: String) async throws -> RecommendationItem {
        if let id = activeCycleId {
            return try await recommendationDocument(cycleId: id, profileId: profileId).getDocument(as: RecommendationItem.self)
        }
    }
    
    
    
    
    
    
    //Gets all the shown Reccommendations, return eventInvite. Save the profile Images all to Cache immedietely. (BIG function)
    
    
    private func fetchPendingProfileIds() async throws -> [String] {
        let query = recommendationsCollection(cycleId: activeCycleId ?? "")
            .whereField(RecommendationItem.CodingKeys.recommendationStatus.stringValue, isEqualTo: RecommendationStatus.pending.rawValue)
        let documents = try await query.getDocuments(as: RecommendationItem.self)
        return documents.map (\.id)
    }
    

    func fetchShownCycleRecommendations() async throws -> [EventInvite] {
    
        let ids = try await fetchPendingProfileIds()
        
        return await withTaskGroup(of: EventInvite.self) { group in
            
            for id in ids {
                group.addTask {
                    if let p = try? await self.profileManager.getProfile(userId: id)  {
                        let firstImage = try? await self.cacheManager?.fetchFirstImage(profile: p)
                        return EventInvite(event: nil, profile: p, image: firstImage ?? UIImage())
                    }
            }
            var results: [EventInvite] = []
            for g in group {
                results.append(g)
            }
            return results
        }
    }
        

        
        
    
    func fetchRecommendations () async throws -> [String] {
        guard let cycleId = activeCycleId else {return []}
        return try await recommendationsCollection(cycleId: cycleId).getDocuments(as: RecommendationItem.self).map {$0.id}
        
        
        
        
        
        
    }
    
    
    
    func updateCycle(key: String, field: Any) {
        guard let activeCycleId else {return}
        cycleDocument(cycleId: activeCycleId).updateData( [key: field] )
    }
    func updateRecommendationItem(profileId: String, key: String, field: Any) {
        guard let activeCycleId else {return}
        recommendationDocument(cycleId: activeCycleId, profileId: profileId).updateData( [key: field] )
    }
    
    //Functions requirred in App
    
    func deleteWeeklyRec() async throws {
        updateCycle(key: "cycleStatus", field: CycleStatus.closed)

        try await profile.update(values: [UserProfile.CodingKeys.activeCycleId: FieldValue.delete()])
    }
    
    func inviteSent(profileId: String) async throws {
        guard let activeCycleId else {return}

        var stats = try await fetchCycle().cycleStats
        stats .pending -= 1
        stats .invited += 1
        
        
        if var weeklyItem = items.first(where: { $0.id == profileId}) {
            weeklyItem.itemStatus = .invited
        }
        session?.removeProfileRec(profileId: profileId)
        
    }
    
    

        
        
    }
    
    

        


    
    func updateForInviteSent(profileId: String) async throws {
        var stats = try await getWeeklyRecDoc().cycleStats
        stats.pending -= 1
        stats.invited += 1
        
        let items = try await getWeeklyItems()
        
        if var weeklyItem = items.first(where: { $0.id == profileId}) {
            weeklyItem.itemStatus = .invited
        }
        session?.removeProfileRec(profileId: profileId)
    }
}

