//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import FirebaseFirestore

enum UpdateShownProfiles {
    case addProfile(id: String)
    case removeProfile(id: String)
}

enum CycleUpdate {
    case added(cycleModel: CycleModel)
    case closed(id: String)
    case respond(id: String)
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
    
    func fetchProfileItem(userId: String, cycleId: String, profileId: String) async throws -> ProfileRec {
        return try await profileDocument(userId: userId, cycleId: cycleId, profileId: profileId).getDocument(as: ProfileRec.self)
    }
    
    func fetchCycleProfiles (userId: String, cycleId: String) async throws -> [String] {
        print("Fetch cycle called ")
        do {
            return try await profilesCollection(userId: userId, cycleId: cycleId)
                .whereField(ProfileRec.Field.status.rawValue, isEqualTo: ProfileRecStatus.pending.rawValue)
                .getDocuments(as: ProfileRec.self)
                .map(\.id)
        } catch {
            print(error)
        }
        return []
    }
    
    
    func pendingProfilesStream(userId: String, cycleId: String) -> AsyncThrowingStream<UpdateShownProfiles, Error> {
        AsyncThrowingStream { continuation in
            print("listener called")
            let reg = profilesCollection(userId: userId, cycleId: cycleId).addSnapshotListener { snapshot, error in
                if let error { continuation.finish(throwing: error); return }
                guard let snap = snapshot else { return }
                for change in snap.documentChanges {
                    guard let item = try? change.document.data(as: ProfileRec.self) else { continue }
                    let isPending: Bool = item.status == .pending
                    switch change.type {
                    case .added, .modified:
                        continuation.yield( isPending ? .addProfile(id: item.id) : .removeProfile(id: item.id))
                    case .removed:
                        break
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
            let newItem = ProfileRec(id: id, profileViews: 0, status: .pending)
            try profileDocument(userId: userId, cycleId: cycleId, profileId: id).setData(from: newItem)
        }
    } // Remove this function once cloud functions does this
    
    
    func updateCycle(userId: String, cycleId: String, data: [String : Any]) {
        cycleDocument(userId: userId, cycleId: cycleId).updateData(data)
    }
    
    
    func updateProfileItem(userId: String, cycleId: String, profileId: String, key: String, field: Any) {
        profileDocument(userId: userId, cycleId: cycleId, profileId: profileId).updateData([key: field])
    }
    
    
    func inviteSent(userId: String, cycle: CycleModel?, profileId: String) {
        guard let id = cycle?.id else { return }
        updateProfileItem(userId: userId, cycleId: id, profileId: profileId, key: ProfileRec.Field.status.rawValue, field: ProfileRecStatus.invited.rawValue)
        
        let statsKey   = CycleModel.Field.cycleStats.rawValue
        let invitedKey = "\(statsKey).\(CycleStats.CodingKeys.invited.stringValue)"
        let pendingKey = "\(statsKey).\(CycleStats.CodingKeys.pending.stringValue)"
        
        cycleDocument(userId: userId, cycleId: id).updateData([
            invitedKey: FieldValue.increment(Int64(1)),
            pendingKey: FieldValue.increment(Int64(-1))
        ])
    }
    
    func fetchCycleStatus(userId: String) async throws  -> (CycleStatus, CycleModel?) {
        let profile = try await userManager.fetchUser(userId: userId)
        guard let cycleId = profile.activeCycleId else { return (.closed, nil) }
        let cycle = try await cycleDocument(userId: userId, cycleId: cycleId).getDocument(as: CycleModel.self)
        let status = cycle.cycleStatus
        return (status, cycle)
    }
    
    func cycleStream(userId: String) -> AsyncThrowingStream<CycleUpdate, Error> {
        AsyncThrowingStream { continuation in
            let reg = cycleCollection(userId: userId).addSnapshotListener { snapshot, error in
                if let error = error { continuation.finish(throwing: error)}
                guard let snap = snapshot else {return}
                for change in snap.documentChanges {
                    if let model = try? change.document.data(as: CycleModel.self), let id = model.id {
                        switch change.type {
                        case .added:
                            if model.cycleStatus == .active { continuation.yield(.added(cycleModel: model)) }
                        case .modified:
                            if model.cycleStatus == .closed {
                                continuation.yield(.closed(id: id))
                            } else if model.cycleStatus == .respond {
                                continuation.yield(.respond(id: id))
                            } else { continue }
                            
                        case .removed:
                            print("removed unexepectedly")
                        }
                    }
                }
            }
            continuation.onTermination = { _ in reg.remove()}
        }
    }
}

