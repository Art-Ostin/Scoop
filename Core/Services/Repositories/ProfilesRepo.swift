//
//  ProfilesRepo.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import SwiftUI


enum UpdateShownProfiles {
    case addProfile(id: String)
    case removeProfile(id: String)
}



class ProfileRepo {
    
    let fs: FirestoreService
    
    init(fs: FirestoreService) {
        self.fs = fs
    }

    private func profilesFolder(userId: String, subfolder: ProfileSubfolder) -> String {
        "users/\(userId)/profiles_\(subfolder.rawValue)"
    }
    private func profilePath(userId: String, subfolder: ProfileSubfolder, profileId: String) -> String {
        "\(profilesFolder(userId: userId, subfolder: subfolder))/\(profileId)"
    }
    
    //Fetches the initial profiles on Launch and listens for any updates
    func profilesListener(userId: String) async throws -> (initial: [ProfileRec], updates: AsyncThrowingStream<UpdateShownProfiles, Error>) {
        let path = profilesFolder(userId: userId, subfolder: .pending)
        let filters: [FSWhere] = [FSWhere(field: ProfileRec.Field.status.rawValue, op: .eq,  value: ProfileRec.Status.pending.rawValue)]
        let initial: [ProfileRec] = try await fs.fetchFromCollection(path, filters: filters, orderBy: nil, limit: nil)
        
        let base: AsyncThrowingStream<FSCollectionEvent<ProfileRec>, Error> = fs.streamCollection(path, filters: [], orderBy: nil, limit: nil)
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
        return (initial, updates)
    }
    
    func updateProfileRec(userId: String, profileId: String, status: ProfileRec.Status) async throws {
        let path = profilePath(userId: userId, subfolder: .pending, profileId: profileId)
        let data: [String: ProfileRec.Status] = [ProfileRec.Field.status.rawValue: status]
        try await fs.update(path, fields: data)
    }
}


private enum ProfileSubfolder: String {
    case pending
    case invited
    case declined
}
