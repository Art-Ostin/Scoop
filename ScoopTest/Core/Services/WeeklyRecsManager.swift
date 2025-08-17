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
    @ObservationIgnored private let profile: ProfileManaging
    @ObservationIgnored private var session: SessionManager?
    
    init(user: UserManager, profile: ProfileManaging, session: SessionManager? = nil) {
        self.user = user
        self.profile = profile
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
    
    
    // Functions to Create the weekly Cycle
    private func createRecommendedProfiles(cycleId: String) async throws {
        let snap = try await users.getDocuments()
        let ids = snap.documents.map( \.documentID ).filter { $0 != currentUserId! }
        let selectdIds = Array(ids.shuffled().prefix(4))
        
        for id in selectdIds {
            let newItem = RecommendationItem(id: id, profileViews: 0, recommendationStatus: .pending)
            try recommendationsCollection(cycleId: cycleId).addDocument(from: newItem)
        }
    }
    func createCycle() async throws {
        let addedCount = 4
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let autoRemoveAt = Calendar.current.date(byAdding: .day, value: 21, to: now)!
        
        let cycle = RecommendationCycle(
            cycleStats: .init(total: addedCount, invited: 0, accepted: 0, dismissed: 0, pending: addedCount),
            profilesAdded: 4,
            endsAt: Timestamp(date: endsAt),
            autoRemoveAt: Timestamp(date: autoRemoveAt)
        )
        
        let docRef = try cyclesCollection().addDocument(from: cycle)
        let id = docRef.documentID
        try await createRecommendedProfiles(cycleId: id)
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
    
    
    func fetchAllRecommendations () async throws -> [String] {
        guard let cycleId = activeCycleId else {return []}
        return try await recommendationsCollection(cycleId: cycleId).getDocuments(as: RecommendationItem.self).map {$0.id}
    }

    
    func updateCycle(key: String, field: Any) {
        
        
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
        session?.removeProfileRec(profileId: profileId)
    }
}

