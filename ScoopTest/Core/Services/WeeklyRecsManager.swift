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
        user.user?.weeklyRecsId
    }
    
    
    //Document and collection Navigations
    private let users = Firestore.firestore().collection("users")
    private func cyclesCollection () -> CollectionReference {
        if  let id = currentUserId {
            users.document(id).collection("recommendation_cycles")
        }
    }
    
    private func cycleDocument() -> DocumentReference {
        if let id = activeCycleId {
            cyclesCollection().document(id)
        }
    }
    private func recommendationsCollection () -> CollectionReference {
        cycleDocument().collection("recommendations")
    }
    private func recommendationDocument(profileId: String) -> DocumentReference {
        recommendationsCollection().document(profileId)
    }
    
    
    
    // Creating a cycleDocument and populating it with profile recommendations
    
    
    
    func createCycle() async throws {
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let autoRemoveAt = Calendar.current.date(byAdding: .day, value: 21, to: Date())!
        
        let cycle = RecommendationCycle(cycleStats: .init(total: 4, invited: 0, accepted: 0, dismissed: 0, pending: 4), profilesAdded: 4, endsAt: endsAt, autoRemoveAt: autoRemoveAt)
        
        
        let docRef = try cyclesCollection().addDocument(from: cycle)
        let id = docRef.getDocument(as: RecommendationCycle.self)
    }
    
    

    
    private func createRecommendedProfiles(cycleId: String) async throws -> [String] {
        let snap = try await users.getDocuments()
        let ids = snap.documents.map( \.documentID ).filter { $0 != currentUserId! }
        let selectdIds = Array(ids.shuffled().prefix(4))
        
        for id in selectdIds {
            let recommendationDocument = RecommendationItem(id: id, profileViews: 0, recommendationStatus: .pending)
            try cycleDocument().setData(from: recommendationDocument)
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
        session?.removeProfileRec(profileId: profileId)
    }
}

