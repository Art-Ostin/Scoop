//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation
import FirebaseAuth
import MapKit

//Updates & stores a 'Draft Profile' during onboarding which persists between sessions. Also saves user's onboarding stage
@Observable
final class DefaultsManager: DefaultsManaging {
    
    
    let defaults: UserDefaults
    private let maxRecentMapSearches = 4
    private enum Keys: String { case draftProfile, onboardingStep, recentMapSearches, preferredMapType, eventDrafts}
    
    
    var onboardingStep: Int = 0 {
        didSet { defaults.set(onboardingStep, forKey: Keys.onboardingStep.rawValue) }
    }

    private(set) var recentMapSearches: [RecentPlace] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(recentMapSearches) {
                defaults.set(data, forKey: Keys.recentMapSearches.rawValue)
            } else {
                defaults.removeObject(forKey: Keys.recentMapSearches.rawValue)
            }
        }
    }
    
//    private(set) var eventDrafts: [String : EventDraft] = [:] {
//        didSet {
//            if let data = try? JSONEncoder().encode(eventDrafts) {
//                defaults.set(data, forKey: Keys.eventDrafts.rawValue)
//            } else {
//                defaults.removeObject(forKey: Keys.eventDrafts.rawValue)
//            }
//        }
//    }
    
    //A local copy (created on init) stored and referenced in code changes to it triggers changes to defaults
    var signUpDraft: DraftProfile? {
        didSet {
            if let draft = signUpDraft, let data = try? JSONEncoder().encode(draft) {
                defaults.set(data, forKey: Keys.draftProfile.rawValue)
            } else {
                defaults.removeObject(forKey: Keys.draftProfile.rawValue) // clear when nil
            }
        }
    }
    
    var preferredMapType: PreferredMapType? {
        didSet {
            if let preferredMapType {
                defaults.set(preferredMapType.rawValue, forKey: Keys.preferredMapType.rawValue)
            } else {
                defaults.removeObject(forKey: Keys.preferredMapType.rawValue)
            }
        }
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
        
//        if let data = defaults.data(forKey: Keys.eventDrafts.rawValue),
//           let drafts = try? JSONDecoder().decode([String : EventDraft].self, from: data) {
//            eventDrafts = drafts
//        }
    }
    
    func createDraftProfile(user: User) {
        signUpDraft = DraftProfile(user: user)
    }
    
    func update<T>(_ keyPath: WritableKeyPath<DraftProfile, T>, to value: T) {
        guard var d = signUpDraft else { return }
        d[keyPath: keyPath] = value
        signUpDraft = d
    }
        
    func deleteDefaults() {
        signUpDraft = nil
        onboardingStep = 0
        recentMapSearches = []
    }
    
    func advanceOnboarding() { onboardingStep += 1 }
    
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
    
//    func updateEventDraft(profileId: String, eventDraft: EventDraft) {
//        self.eventDrafts[profileId] = eventDraft
//    }
//    
//    func fetchEventDraft(profileId: String) -> EventDraft? {
//        return self.eventDrafts[profileId]
//    }
//    func deleteEventDraft(profileId: String) {
//        eventDrafts.removeValue(forKey: profileId)
//    }
}


enum PreferredMapType: String, Codable {
    case appleMaps, googleMaps
}


struct RecentPlace: Codable, Equatable, Hashable {
    let title: String
    let town: String
}
