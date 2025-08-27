//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import FirebaseFirestore

enum PendingRecEvent {
    case addedPending(id: String)
    case movedToInvite(id: String)
}


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
    
    func pendingProfilesStream(userId: String, cycleId: String) -> AsyncThrowingStream<PendingRecEvent, Error> {
        AsyncThrowingStream { continuation in
            
            let reg = profilesCollection(userId: userId, cycleId: cycleId).addSnapshotListener { snapshot, error in
                if let error { continuation.finish(throwing: error); return }
                guard let snap = snapshot else {return}
                
                for change in snap.documentChanges {
                    switch change.type {
                    case .added:
                        if let item = try? change.document.data(as: RecommendationItem.self), item.recommendationStatus == .pending {
                            continuation.yield(.addedPending(id: item.id))
                        }
                    case .modified:
                        if let item = try? change.document.data(as: RecommendationItem.self), item.recommendationStatus == .invited {
                            continuation.yield(.movedToInvite(id: item.id))
                        }
                    case .removed:
                        print("removed")
                    }
                }
            }
            continuation.onTermination = { _ in reg.remove() }
        }
    }

    
    
    @discardableResult
    func createCycle(userId: String) async throws -> String {
        let addedCount = 4
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .second, value: 30, to: now)!
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
        try await userManager.updateUser(values: [UserProfile.Field.activeCycleId: id])
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
    

    func updateCycle(userId: String, cycleId: String, data: [String : Any]) {
        cycleDocument(userId: userId, cycleId: cycleId).updateData(data)
    }

    
    func updateProfileItem(userId: String, cycleId: String, profileId: String, key: String, field: Any) {
        profileDocument(userId: userId, cycleId: cycleId, profileId: profileId).updateData([key: field])
    }
        
    
    func checkCycleStatus (userId: String, cycle: CycleModel?) async -> CycleStatus {
        guard let cycle, let id = cycle.id else  {return .closed }
        if Date() > cycle.endsAt.dateValue() {
            if cycle.cycleStats.pending == 0 || Date() > cycle.autoRemoveAt.dateValue() {
                try? await deleteCycle(userId: userId, cycleId: id)
                print("closed")
                return .closed
            } else {
                updateCycle(userId: userId, cycleId: id, data: [CycleModel.CodingKeys.cycleStatus.stringValue : CycleStatus.respond.rawValue])
                print("respond")
                return .respond
            }
        } else {
            print("active")
            return .active
        }
    }
    
    func inviteSent(userId: String, cycle: CycleModel?, profileId: String) {
        guard let id = cycle?.id else { return }
        updateProfileItem(userId: userId, cycleId: id, profileId: profileId, key: RecommendationItem.CodingKeys.recommendationStatus.stringValue, field: RecommendationStatus.invited.rawValue)

        let statsKey   = CycleModel.CodingKeys.cycleStats.stringValue
        let invitedKey = "\(statsKey).\(CycleStats.CodingKeys.invited.stringValue)"
        let pendingKey = "\(statsKey).\(CycleStats.CodingKeys.pending.stringValue)"
    
        cycleDocument(userId: userId, cycleId: id).updateData([
            invitedKey: FieldValue.increment(Int64(1)),
            pendingKey: FieldValue.increment(Int64(-1))
        ])
    }
    
    
    func deleteCycle(userId: String, cycleId: String) async throws {
        updateCycle(userId: userId, cycleId: cycleId, data: [CycleModel.CodingKeys.cycleStatus.stringValue : CycleStatus.closed.rawValue])
        try await userManager.updateUser(values: [UserProfile.Field.activeCycleId: FieldValue.delete()])
    }
}



//A listener set up for the CycleModel
/*
 func userRecsStream(userId: String, cycleId: String) -> AsyncThrowingStream<CycleModel?, Error> {
     AsyncThrowingStream { continuation in
         cycleDocument(userId: userId, cycleId: cycleId).addSnapshotListener { snapshot, error in
             if let error = error {continuation.finish(throwing: error) ; return }
             guard let snap = snapshot else { return }
             guard snap.exists else { continuation.yield(nil); return }
             do{ continuation.yield(try snap.data(as: CycleModel.self))}
             catch{continuation.finish(throwing: error) ; return }
         }
     }
 }
 */
