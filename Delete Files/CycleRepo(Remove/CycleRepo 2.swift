//
//  WeeklyRecsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

//Change this to Profiles Repo which recommends the profiles for user (i.e. Delete the Cycle Repos)
//In Events Have (1) Sent-Declined (2) Received-Declined (3) Invited (4) Sent (5) 



/*
 
 import Foundation
 import Firebase
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
     
     func createCycle(userId: String) async throws -> String {
         let addedCount = 4
         let now = Date()
         let endsAt = Calendar.current.date(byAdding: .second, value: 30, to: now)!
         let autoRemoveAt = Calendar.current.date(byAdding: .day, value: 21, to: now)!
         
         let cycle = CycleModel(cycleStats: CycleStats(total: addedCount, invited: 0, accepted: 0, dismissed: 0, pending: addedCount),profilesAdded: addedCount,endsAt: endsAt,autoRemoveAt: autoRemoveAt)
         let id = try fs.add(cyclePath(userId: userId), value: cycle)
         try await createRecommendations(cycleId: id, userId: userId)
         return id
     }
     
     func createRecommendations(cycleId: String, userId: String) async throws {
         let snap = try await Firestore.firestore().collection("users").getDocuments()
          let ids = snap.documents.map( \.documentID ).filter { $0 != userId }
          let selectdIds = Array(ids.shuffled().prefix(4))
          for id in selectdIds {
              let profileRec = (ProfileRec(id: id, profileViews: 0, status: .pending))
              try fs.set(profileDocument(userId: userId, cycleId: cycleId, profileId: id), value: profileRec)
          }
     }

     
     func fetchCycleModel(userId: String, cycleId: String) async throws -> CycleModel {
         try await fs.get(cycleDocPath(userId: userId, cycleId: cycleId))
     }
     
     
     func updateCycle(userId: String, cycleId: String, values: [String: Any]) async throws  {
         try await fs.update(cycleDocPath(userId: userId, cycleId: cycleId), fields: values)
     }
     
     func updateCycleProfile(userId: String, cycleId: String, profileId: String, values: [ProfileRec.Field : Any]) async throws  {
         var data: [String: Any] = [:]
         for (key, value) in values { data[key.rawValue] = value}
         try await fs.update(profileDocument(userId: userId, cycleId: cycleId, profileId: profileId), fields: data)
     }
     
     func inviteSent(userId: String, cycle: CycleModel?, profileId: String) async throws {
         guard let id = cycle?.id else { return }
         try await updateCycleProfile(userId: userId, cycleId: id, profileId: profileId, values: [.status : ProfileRecStatus.invited.rawValue])
             fs.increment(cycleDocPath(userId: userId, cycleId: id), by: [ "cycleStats.invited":  1, "cycleStats.pending": -1])
     }
     
     func declineProfile(userId: String, cycle: CycleModel?, profileId: String) async throws {
         guard let id = cycle?.id  else { return}
         try await updateCycleProfile(userId: userId, cycleId: id, profileId: profileId, values: [.status : ProfileRecStatus.dismiss.rawValue])
         fs.increment(cycleDocPath(userId: userId, cycleId: id), by: [ "cycleStats.dismissed":  1, "cycleStats.pending": -1])
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
                         case .removed(_):
                             break
                         }
                     }
                     continuation.finish()
                 } catch { continuation.finish(throwing: error) }
             }
         }
         return (initial, updates)
     }
     
     func cycleListener(userId: String, cycleId: String) -> AsyncThrowingStream<CycleModel?, Error> {
         fs.listenD(cycleDocPath(userId: userId, cycleId: cycleId))
     }
 }
 */



