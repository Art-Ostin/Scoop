//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation

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
    
    private var fs: FirestoreService
    private var cacheManager: CacheManaging
    private var userManager: UserManager
    
    init(cacheManager: CacheManaging, userManager: UserManager, fs: FirestoreService) {
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.fs = fs
    }
    
    private func cyclePath (userId: String) -> String {
        "users/\(userId)/recommendation_cycles"
    }
    
    private func cycleDocPath(userId: String, cycleId: String) -> String {
        "users/\(userId)/recommendation_cycles/\(cycleId)"
    }
    
    private func profilesPath (userId: String, cycleId: String) -> String {
        "\(cycleDocPath(userId: userId, cycleId: cycleId))/recommendations"
    }
    
    private func profileDocument(userId: String, cycleId: String, profileId: String) -> String {
        "\(profilesPath(userId: userId, cycleId: cycleId))/\(profileId)"
    }
    
    func fetchCycle(user: UserProfile) async throws -> CycleModel? {
        guard let cycleId = user.activeCycleId else { return nil }
        return try await fs.get(cycleDocPath(userId: user.id, cycleId: cycleId))
    }
    
    func fetchCycleProfile(userId: String, cycleId: String, profileId: String) async throws -> ProfileRec {
        try await fs.get(profileDocument(userId: userId, cycleId: cycleId, profileId: profileId))
    }
        
    @discardableResult
    func createCycle(userId: String) async throws -> String {
        let addedCount = 4
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .second, value: 30, to: now)!
        let autoRemoveAt = Calendar.current.date(byAdding: .day, value: 21, to: now)!
        
        let cycle = CycleModel(cycleStats: CycleStats(total: addedCount, invited: 0, accepted: 0, dismissed: 0, pending: addedCount),profilesAdded: addedCount,endsAt: endsAt,autoRemoveAt: autoRemoveAt)
        
        let id = try fs.add(cyclePath(userId: userId), value: cycle)
        
        //Have a function to get the profiles when they appear
        /*
         let snap = try await users.getDocuments()
         let ids = snap.documents.map( \.documentID ).filter { $0 != userId }
         let selectdIds = Array(ids.shuffled().prefix(4))
         var newProfiles: [ProfileRec] = []
         for id in selectedIds {
         newProfiles.append(ProfileRec(id: id, profileViews: 0, status: .pending))
         fs.set(cyclePath(userId: userId), value: newProfiles)
         }
         */
    }
    
    func updateCycle(userId: String, cycleId: String, values: [String: Any]) {
        fs.update(cycleDocPath(userId: userId, cycleId: cycleId), fields: values)
    }
    
    func updateCycleProfile(userId: String, cycleId: String, profileId: String, values: [ProfileRec.Field : Any]) {
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value}
        fs.update(profileDocument(userId: userId, cycleId: cycleId, profileId: profileId), fields: data)
    }
    
    func inviteSent(userId: String, cycle: CycleModel?, profileId: String) {
        guard let id = cycle?.id else { return }
        updateCycleProfile(userId: userId, cycleId: id, profileId: profileId, values: [.status : ProfileRecStatus.invited.rawValue])
            fs.increment(cycleDocPath(userId: userId, cycleId: id), by: [ "cycleStats.invited":  1, "cycleStats.pending": -1])
    }
    
    func fetchCycleStatus(user: UserProfile) async throws -> (CycleStatus, CycleModel?) {
        guard let cycleId = user.activeCycleId else { return (.closed, nil) }
        let cycle: CycleModel = try await fs.get(cycleDocPath(userId: user.id, cycleId: cycleId))
        let status = cycle.cycleStatus
        return (status, cycle)
    }
    
    func profilesTracker(userId: String, cycleId: String) async throws -> (initial: [ProfileRec], updates: AsyncThrowingStream<UpdateShownProfiles, Error>) {
        let path = "users/\(userId)/recommendation_cycles/\(cycleId)/recommendations"
        let filters: [FSWhere] = [FSWhere(field: ProfileRec.Field.status.rawValue, op: .eq,  value: ProfileRecStatus.pending.rawValue)]
        let initial: [ProfileRec] = try await fs.fetchFromCollection(path, filters: filters, orderBy: nil, limit: nil)
        
        let base: AsyncThrowingStream<FSCollectionEvent<ProfileRec>, Error> = fs.streamCollection(path, filters: [], orderBy: nil, limit: nil)
        
        let updates = AsyncThrowingStream<UpdateShownProfiles, Error> { continuation in
            Task {
                do {
                    for try await rec in base {
                        switch rec {
                        case .initial:
                            continue
                        case .added(let it), .modified(let it):
                            if it.model.status != .pending {
                                continuation.yield(.removeProfile(id: it.id))
                            } else {
                                continuation.yield(.addProfile(id: it.id))
                            }
                            
                        case .removed(let id):
                            break
                        }
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
        }
        return (initial, updates)
    }
    
    func cycleTracker(userId: String) async throws -> (initial: CycleModel, updates: AsyncThrowingStream<CycleUpdate, Error>) {
        let path = cyclePath(userId: userId)
        let filters: [FSWhere] = [FSWhere(field: CycleModel.Field.cycleStatus.rawValue, op: .eq, value: CycleStatus.active)]
        let initial: CycleModel = try await fs.get(path)
        
        let base: AsyncThrowingStream<FSCollectionEvent<CycleModel>, Error> = fs.streamCollection(path, filters: [], orderBy: nil, limit: nil)
        let updates = AsyncThrowingStream<CycleUpdate, Error> { continuation in
            Task {
                do {
                    for try await cycle in base {
                        switch cycle {
                        case .initial:
                            continue
                            
                        case .added(let it):
                            if it.model.cycleStatus.rawValue == CycleStatus.active.rawValue {
                                continuation.yield(CycleUpdate.added(cycleModel: it.model))
                            }
                        case .modified(let it):
                            if it.model.cycleStatus.rawValue == CycleStatus.respond.rawValue {
                                continuation.yield(CycleUpdate.respond(id: it.id))
                            } else if it.model.cycleStatus.rawValue == CycleStatus.closed.rawValue {
                                continuation.yield(CycleUpdate.closed(id: it.id))
                            }
                        case .removed(let it):
                            break
                        }
                    }
                }
            }
        }
        
    }
}

/*
 func fetchCycleProfiles (userId: String, cycleId: String) async throws -> [String] {
     let snap = try await profilesCollection(userId: userId, cycleId: cycleId)
         .whereField(ProfileRec.Field.status.rawValue, isEqualTo: ProfileRecStatus.pending.rawValue)
         .getDocuments()
     return snap.documents.map(\.documentID)
 }
 */

/*
 func inviteSent(userId: String, cycle: CycleModel?, profileId: String) {
     guard let id = cycle?.id else { return }
     updateCycleProfile(userId: userId, cycleId: id, profileId: profileId, values: [.status : ProfileRecStatus.invited.rawValue])
     updateCycle(userId: userId,  cycleId: id, fields: [
             "cycleStats.invited": FieldValue.increment(Int64(1)),
             "cycleStats.pending": FieldValue.increment(Int64(-1))
         ]
     )

     
     
     
     let statsKey   = CycleModel.Field.cycleStats.rawValue
     let invitedKey = "\(statsKey).\(CycleStats.CodingKeys.invited.stringValue)"
     let pendingKey = "\(statsKey).\(CycleStats.CodingKeys.pending.stringValue)"

     updateCycle(userId: userId, cycleId: id, values: invitedKey : FieldValue.increment(Int64(1)), pendingKey : FieldValue.increment(Int64(-1)))
 }
 */
/*
 func cycleStream(userId: String) -> AsyncThrowingStream<CycleUpdate, Error> {
     AsyncThrowingStream { continuation in
         let reg = cycleCollection(userId: userId).addSnapshotListener { snapshot, error in
             if let error = error { continuation.finish(throwing: error)}
             guard let snap = snapshot else {return}
             for change in snap.documentChanges {
                 print("loading on launch")
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

 */
