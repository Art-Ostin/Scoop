//
//  ProfilesSession.swift
//  Scoop
//
//  Created by Art Ostin on 02/05/2026.
//

import SwiftUI
import os

private let profilesLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Scoop", category: "profiles")

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
        //Stamp who this load is for. Firestore's continuations don't observe cancellation, so a
        //sign-out mid-flight would otherwise land this account's declines in the next one's session
        //— the leak stopSession()'s clear exists to stop.
        let loadingFor = user.id
        
        do {
            //Fetch all the user 'profiles' where status is 'declined' and in last 5 days
            let declinedRecs = try await profilesRepo.recentlyDeclined(userId: loadingFor, since: since)
            
            //From the ids, load the profiles up
            let loadedProfiles = try await profileLoader.fromIds(declinedRecs.compactMap { $0.id })

            //Pair each rec's decline timestamp back onto its loaded profile. A rec with no
            //timestamp, or one whose profile failed to load, simply drops out of History.
            let declined = declinedRecs.compactMap { rec -> DeclinedProfile? in
                guard let id = rec.id, let declinedAt = rec.updatedAt,
                      let profile = loadedProfiles.first(where: { $0.id == id }) else { return nil }
                return DeclinedProfile(profile: profile, declinedAt: declinedAt)
            }
            guard sessionUser?.id == loadingFor else { return }
            mergeDeclined(declined)
        } catch {
            //Never swallow this one: a silent failure here is indistinguishable from "nothing
            //declined", which is exactly how the missing-composite-index bug stayed invisible for
            //days. The query no longer needs that index, but any future read failure must still show.
            profilesLog.error("Failed to load recently declined profiles: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    //The fetch runs as a launch task, so anything declined locally while it was in flight has to
    //survive it. The server's copy wins where both have the profile — its timestamp is authoritative.
    private func mergeDeclined(_ fetched: [DeclinedProfile]) {
        let fetchedIds = Set(fetched.map(\.id))
        let localOnly = declinedProfiles.filter { !fetchedIds.contains($0.id) }
        declinedProfiles = (fetched + localOnly).sorted { $0.declinedAt > $1.declinedAt }
    }
    
    //Locally move a profile out of the pending list into the declined store — no network, it's already
    //loaded. The caller hands the profile in rather than an id because the profiles listener prunes the
    //rec from `profiles` the moment the decline write lands locally, which is before that write returns.
    func declineProfile(_ profile: PendingProfile) {
        profiles.removeAll { $0.id == profile.id }
        //Drop any older entry rather than skipping: a re-declined profile takes the fresh
        //timestamp, so it can't fall out of the 5-day window on its first decline's clock
        declinedProfiles.removeAll { $0.id == profile.id }
        declinedProfiles.insert(DeclinedProfile(profile: profile, declinedAt: .now), at: 0)
    }
    
    
}
