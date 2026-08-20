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
    
    //Update profile Rec to whatever status I set, and with a timestamp
    func updateProfileRec(userId: String, profileId: String, status: ProfileRec.Status) async throws {
        let path = profilePath(userId: userId, profileId: profileId)
        let data: [String: Any] = [
            ProfileRec.Field.status.rawValue: status.rawValue,
            ProfileRec.Field.updatedDay.rawValue : FieldValue.serverTimestamp()
        ]
        try await fs.update(path, fields: data)
    }
    
    func recentlyDeclined(userId: String, since: Date) async throws -> [ProfileRec]{
        typealias F = ProfileRec.Field
        return try await fs.fetchFromCollection(profilesFolder(userId: userId)) {
            $0.whereField(F.status.rawValue, isEqualTo: ProfileRec.Status.declined.rawValue)
              .whereField(F.updatedDay.rawValue, isGreaterThan: Timestamp(date: since))
              .order(by: F.updatedDay.rawValue, descending: true)
        }
    }
}
