//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation
import FirebaseAuth
import MapKit

//Method: Have variables referenced throughout code. When these values updated, save the new value to defaults (with the didSet functionality).

@MainActor
@Observable
final class DefaultsManager {
    
    @ObservationIgnored let defaults: UserDefaults
    private let maxRecentMapSearches = 4
    
    private(set) var onboardingStep: Int = 0 {
        didSet { saveOnboardingStepToDefaults() }
    }
    
    private(set) var signUpDraft: DraftProfile? {
        didSet { saveSignUpDraftToDefaults() }
    }
    
    private(set) var recentMapSearches: [RecentPlace] = [] {
        didSet { saveRecentMapSearchesToDefaults()}
    }
    
    private(set) var preferredMapType: PreferredMapType? {
        didSet { savePreferredMapToDefaults() }
    }
    
    private(set) var eventDrafts: [String : EventDraft] = [:] {
        didSet { saveEventDraftsToDefaults() }
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFromDefaults()
    }
    
    func loadFromDefaults() {
        self.onboardingStep = defaults.object(forKey: Keys.onboardingStep.rawValue) as? Int ?? 0
        
        if let data = defaults.data(forKey: Keys.draftProfile.rawValue) {
            signUpDraft = try? JSONDecoder().decode(DraftProfile.self, from: data)
        }
        if let data = defaults.data(forKey: Keys.recentMapSearches.rawValue),
           let recents = try? JSONDecoder().decode([RecentPlace].self, from: data) {
            recentMapSearches = recents
        }
        
        if let rawMapType = defaults.string(forKey: Keys.preferredMapType.rawValue) {
            preferredMapType = PreferredMapType(rawValue: rawMapType)
        }
        
        if let data = defaults.data(forKey: Keys.eventDrafts.rawValue),
           let drafts = try? JSONDecoder().decode([String : EventDraft].self, from: data) {
            eventDrafts = drafts
        }
    }
    
    func deleteDefaults() {
        // remove values in UserDefaults
        for key in Keys.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
        
        //remove in-memory values
        signUpDraft = nil
        onboardingStep = 0
        recentMapSearches = []
        preferredMapType = nil
        eventDrafts.removeAll()
    }
        
}

//Map Related Defaults
extension DefaultsManager {
    
    func updateRecentMapSearches(title: String, town: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTown = town.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedTown.isEmpty else { return }
        
        recentMapSearches.removeAll {
            $0.title.caseInsensitiveCompare(trimmedTitle) == .orderedSame &&
            $0.town.caseInsensitiveCompare(trimmedTown) == .orderedSame
        }
        recentMapSearches.append(RecentPlace(title: trimmedTitle, town: trimmedTown))
        
        if recentMapSearches.count > maxRecentMapSearches {
            recentMapSearches.removeFirst(recentMapSearches.count - maxRecentMapSearches)
        }
    }
    
    func removeFromRecentMapSearches(place: RecentPlace) {
        recentMapSearches.removeAll { $0 == place }
    }
    
    func updatePreferredMapType(mapType: PreferredMapType?) {
        preferredMapType = mapType
    }
    
    private func saveRecentMapSearchesToDefaults() {
        if let data = try? JSONEncoder().encode(recentMapSearches) {
            defaults.set(data, forKey: Keys.recentMapSearches.rawValue)
        }
    }
    
    private func savePreferredMapToDefaults() {
        if let data = try? JSONEncoder().encode(preferredMapType) {
            defaults.set(data, forKey: Keys.preferredMapType.rawValue)
        }
    }
}

//Draft Events related Defaults
extension DefaultsManager {
    func updateEventDraft(profileId: String, eventDraft: EventDraft) {
        eventDrafts[profileId] = eventDraft
    }
    
    func fetchEventDraft(profileId: String) -> EventDraft? {
        eventDrafts[profileId]
    }
    
    func deleteEventDraft(profileId: String) {
        eventDrafts.removeValue(forKey: profileId)
    }
        
    private func saveEventDraftsToDefaults() {
        if let data = try? JSONEncoder().encode(eventDrafts) {
            defaults.set(data, forKey: Keys.eventDrafts.rawValue)
        }
    }
}

//Draft Profile related Defaults
extension DefaultsManager {
    
    func createDraftProfile(user: User) {
        signUpDraft = DraftProfile(user: user)
    }
    
    func advanceOnboarding() { onboardingStep += 1 }

    func update<T>(_ keyPath: WritableKeyPath<DraftProfile, T>, to value: T) {
        guard var d = signUpDraft else { return }
        d[keyPath: keyPath] = value
        signUpDraft = d
    }
    
    func saveOnboardingStepToDefaults() {
        defaults.set(onboardingStep, forKey: Keys.onboardingStep.rawValue)
    }
    
    private func saveSignUpDraftToDefaults() {
        if let draft = signUpDraft, let data = try? JSONEncoder().encode(draft) {
            defaults.set(data, forKey: Keys.draftProfile.rawValue)
        }
    }
}



extension DefaultsManager {
    private enum Keys: String, CaseIterable {
        case draftProfile,
             onboardingStep,
             recentMapSearches,
             preferredMapType,
             eventDrafts
    }
}


enum PreferredMapType: String, Codable {
    case appleMaps, googleMaps
}


struct RecentPlace: Codable, Equatable, Hashable {
    let title: String
    let town: String
}


/*
 private func persistEventDrafts() {
     if eventDraftsByProfileId.isEmpty {
         defaults.removeObject(forKey: Keys.eventDrafts.rawValue)
         return
     }
     
     if let data = try? JSONEncoder().encode(eventDraftsByProfileId) {
         defaults.set(data, forKey: Keys.eventDrafts.rawValue)
     } else {
         defaults.removeObject(forKey: Keys.eventDrafts.rawValue)
     }
 }
 */
