//
//  ProfilesSessionManager.swift
//  Scoop
//
//  Created by Art Ostin on 02/05/2026.
//

import SwiftUI

//Logic dealing with the recommended Profiles shown to the User
extension SessionManager {
    func profilesStream() {
        subscribe("profiles", to: profilesRepo.profilesTracker(userId: user.id)) { [weak self] change in
            guard let self else { return }
            switch change {
            case .initial(let recs): try await loadInitialProfiles(recs)
            case .added(let rec): try await loadAddedProfile(rec)
            case .modified: break //Don't do anything if profile modified as often case
            case .removed(let id): removeProfileRec(id)

            }
        }
    }
    
    private func loadInitialProfiles(_ recs: [ProfileRec]) async throws {
        let loadedProfile = try await self.profileLoader.fromIds(recs.compactMap { $0.id })
        self.profiles = loadedProfile
        profilesHaveLoaded = true
        if let sessionUser { openMainApp(for: sessionUser) }
    }
    
    private func loadAddedProfile(_ rec: ProfileRec) async throws {
        if let id = rec.id {
            let newProfileRec = try await self.profileLoader.fromIds([id])
            self.profiles.append(contentsOf: newProfileRec)
        }
    }
    
    private func removeProfileRec(_ id: String) {
        self.profiles.removeAll { $0.id == id }
    }
}
