//
//  ProfilesRepo.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import SwiftUI
import FirebaseFirestore


enum UpdateShownProfiles {
    case addProfile(id: String)
    case removeProfile(id: String)
}

class ProfileRepo: ProfilesRepository {
    
    let fs: FirestoreService
    init(fs: FirestoreService) {self.fs = fs}

    private func profilesFolder(userId: String) -> String {
        "users/\(userId)/profiles"
    }
    
    private func profilePath(userId: String, profileId: String) -> String {
        "\(profilesFolder(userId: userId))/\(profileId)"
    }
    
    //Fetches the initial profiles on Launch and listens for any updates
    func profilesTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<ProfileRec>, Error> {
        let profilesPath = "users/\(userId)/profiles"
        return fs.streamCollection(profilesPath) {$0.whereField(ProfileRec.Field.status.rawValue, isEqualTo: ProfileRec.Status.pending.rawValue)}
    }
        
    func updateProfileRec(userId: String, profileId: String, status: ProfileRec.Status) async throws {
        let path = profilePath(userId: userId, profileId: profileId)
        let data: [String: Any] = [ProfileRec.Field.status.rawValue: status.rawValue]
        try await fs.update(path, fields: data)
    }
}






/*
 func profilesListener(userId: String) async throws -> (initial: [ProfileRec], updates: AsyncThrowingStream<UpdateShownProfiles, Error>) {
     let path = profilesFolder(userId: userId)
     let initial: [ProfileRec] = try await fs.fetchFromCollection(path) {
         $0.whereField(ProfileRec.Field.status.rawValue, isEqualTo: ProfileRec.Status.pending.rawValue)
     }
     
     let base: AsyncThrowingStream<FSCollectionEvent<ProfileRec>, Error> = fs.streamCollection(path)
     let updates = AsyncThrowingStream<UpdateShownProfiles, Error> { continuation in
         Task {
             do { //Don't do anything with initial docs in file, but when added or modified remove if not pending otherwise return
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
     print(initial)
     return (initial, updates)
 }
 */
