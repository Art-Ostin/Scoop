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
