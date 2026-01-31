//
//  ProfilesRepo.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import SwiftUI

class ProfileRepo {
    
    private func profilesPath(userId: String) -> String {
        return "users/\(userId)/profiles"
    }
    
    
    //Set up a listener for that folder when Ids added they appear. 
}






/*
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

 */
