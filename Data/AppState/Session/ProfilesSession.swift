//
//  ProfilesSession.swift
//  Scoop
//
//  Created by Art Ostin on 02/05/2026.
//

import SwiftUI

//Logic dealing with the recommended Profiles shown to the User
extension Session {
        
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


//Logic dealing with loading and showing the declined profiles
extension Session {
    
    //Any profile you have declined from the 5 previous days
    static let daysToShowDeclined: CGFloat = 5
    static let declinedWindow: TimeInterval = daysToShowDeclined * 24 * 60 * 60
    
    
    //Checked fresh each time a view reads it, and so profiles drop off once they're over 5 days old
    var recentlyDeclinedProfiles: [DeclinedProfile] {
        declinedProfiles.filter { $0.declinedAt > .now.addingTimeInterval(-Session.declinedWindow) }
    }
    
    //Upon launch load the recently declined profiles
    func loadRecentlyDeclined() async {
        //Only want profiles who were declined in the last 5 days. So this gets 'last 5 days'.
        let since = Date.now.addingTimeInterval(-Session.declinedWindow)
        
        guard
            //Fetch all the user 'profiles' where status is 'declined' and in last 5 days
            let declinedRecsIds = try? await profilesRepo.recentlyDeclined(userId: user.id, since: since),
            
            //From the ids, load the profiles up
            let declineRecProfiles = try? await profileLoader.fromIds(declinedRecsIds.compactMap { $0.id })
        else { return }
        
        
        //Now I have batch of pending profile, create the DeclinedProfile by extracting the 'updatedAt' from it.
        var declined: [DeclinedProfile] = []
        for rec in declinedRecsIds {
            guard let id = rec.id, let declinedAt = rec.updatedAt else { continue }
            guard let profile = declineRecProfiles.first(where: { $0.id == id }) else { continue }
            declined.append(DeclinedProfile(profile: profile, declinedAt: declinedAt))
        }
        declinedProfiles = declined
    }
    
    //Locally move a profile out of the pending list into the declined store — no network, it's already loaded
    func declineProfile(id: String) {
        guard let i = profiles.firstIndex(where: { $0.id == id }) else { return }
        let declined = profiles.remove(at: i)
        declinedProfiles.insert(DeclinedProfile(profile: declined, declinedAt: .now), at: 0)
    }
    
    
}
