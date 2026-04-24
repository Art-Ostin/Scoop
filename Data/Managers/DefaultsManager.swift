//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation
import FirebaseAuth

@Observable
final class DefaultsManager: DefaultsManaging {

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let maxRecentMapSearches = 4
    @ObservationIgnored private let encoder = JSONEncoder()
    @ObservationIgnored private let decoder = JSONDecoder()

    private(set) var onboardingStep: Int = 0
    private(set) var signUpDraft: DraftProfile?
    private(set) var recentMapSearches: [RecentPlace] = []
    private(set) var preferredMapType: PreferredMapType?
    private(set) var eventDrafts: [String: EventDraft] = [:]
    private(set) var respondDrafts: [String : RespondDraft] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFromDefaults()
    }

    func deleteDefaults() {
        for key in Keys.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }

        onboardingStep = 0
        signUpDraft = nil
        recentMapSearches = []
        preferredMapType = nil
        eventDrafts = [:]
        respondDrafts = [:]
    }
}

// Draft Profile related defaults
extension DefaultsManager {

    func createDraftProfile(user: User) {
        signUpDraft = DraftProfile(user: user)
        persistSignUpDraft()
    }

    func clearSignUpDraft() {
        signUpDraft = nil
        defaults.removeObject(forKey: Keys.draftProfile.rawValue)
    }

    func mutateSignUpDraft(_ mutation: (inout DraftProfile) -> Void) {
        guard var draft = signUpDraft else { return }
        mutation(&draft)
        signUpDraft = draft
        persistSignUpDraft()
    }

    func update<T>(_ keyPath: WritableKeyPath<DraftProfile, T>, to value: T) {
        mutateSignUpDraft { $0[keyPath: keyPath] = value }
    }

    func advanceOnboarding() {
        onboardingStep += 1
        persistOnboardingStep()
    }

    func retreatOnboarding() {
        guard onboardingStep > 0 else { return }
        onboardingStep -= 1
        persistOnboardingStep()
    }
}

// Map related defaults
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

        persistRecentMapSearches()
    }

    func removeFromRecentMapSearches(place: RecentPlace) {
        recentMapSearches.removeAll { $0 == place }
        persistRecentMapSearches()
    }

    func updatePreferredMapType(mapType: PreferredMapType?) {
        preferredMapType = mapType
        persistPreferredMapType()
    }
}

// Draft Event related defaults
extension DefaultsManager {
    func updateEventDraft(profileId: String, eventDraft: EventDraft) {
        eventDrafts[profileId] = eventDraft
        persistEventDrafts()
    }

    func fetchEventDraft(profileId: String) -> EventDraft? {
        return eventDrafts[profileId]
    }

    func deleteEventDraft(profileId: String) {
        eventDrafts.removeValue(forKey: profileId)
        persistEventDrafts()
    }
}

//Logic for saving Respond Drafts
extension DefaultsManager {
    
    func updateRespondDraft(profileId: String, respondDraft: RespondDraft) {
        respondDrafts[profileId] = respondDraft
        persistResponseDrafts()
    }
    
    func fetchRespondDraft(profileId: String) -> RespondDraft? {
        respondDrafts[profileId]
    }
    
    func deleteRespondDraft(profileId: String) {
        respondDrafts.removeValue(forKey: profileId)
        persistResponseDrafts()
    }
}

private extension DefaultsManager {

    func loadFromDefaults() {
        onboardingStep = max(0, defaults.object(forKey: Keys.onboardingStep.rawValue) as? Int ?? 0)
        signUpDraft = decode(DraftProfile.self, for: .draftProfile)
        recentMapSearches = decode([RecentPlace].self, for: .recentMapSearches) ?? []
        preferredMapType = defaults.string(forKey: Keys.preferredMapType.rawValue)
            .flatMap(PreferredMapType.init(rawValue:))
        eventDrafts = decode([String: EventDraft].self, for: .eventDrafts) ?? [:]
        let storedRespondDrafts = decode([String: PersistableRespondDraft].self, for: .responseDrafts) ?? [:]
        respondDrafts = storedRespondDrafts.mapValues { RespondDraft($0) }
    }
    
    func persistResponseDrafts() {
        guard !respondDrafts.isEmpty else {
            defaults.removeObject(forKey: Keys.responseDrafts.rawValue)
            return
        }
        let dto = respondDrafts.mapValues { PersistableRespondDraft($0) }
        encode(dto, for: .responseDrafts)
    }

    func persistOnboardingStep() {
        defaults.set(onboardingStep, forKey: Keys.onboardingStep.rawValue)
    }

    func persistSignUpDraft() {
        guard let signUpDraft else {
            defaults.removeObject(forKey: Keys.draftProfile.rawValue)
            return
        }
        encode(signUpDraft, for: .draftProfile)
    }

    func persistRecentMapSearches() {
        guard !recentMapSearches.isEmpty else {
            defaults.removeObject(forKey: Keys.recentMapSearches.rawValue)
            return
        }
        encode(recentMapSearches, for: .recentMapSearches)
    }

    func persistPreferredMapType() {
        guard let preferredMapType else {
            defaults.removeObject(forKey: Keys.preferredMapType.rawValue)
            return
        }
        defaults.set(preferredMapType.rawValue, forKey: Keys.preferredMapType.rawValue)
    }

    func persistEventDrafts() {
        guard !eventDrafts.isEmpty else {
            defaults.removeObject(forKey: Keys.eventDrafts.rawValue)
            return
        }
        encode(eventDrafts, for: .eventDrafts)
    }

    private func encode<T: Encodable>(_ value: T, for key: Keys) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key.rawValue)
        } catch {
            // TEMP DIAGNOSTIC — remove once persistence bug is resolved.
            print("⚠️ DefaultsManager.encode failed for key \(key.rawValue) (\(T.self)): \(error)")
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, for key: Keys) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            // TEMP DIAGNOSTIC — remove once persistence bug is resolved.
            print("⚠️ DefaultsManager.decode failed for key \(key.rawValue) (\(T.self)): \(error)")
            return nil
        }
    }

    private enum Keys: String, CaseIterable {
        case draftProfile
        case onboardingStep
        case recentMapSearches
        case preferredMapType
        case eventDrafts
        case responseDrafts
    }
}

enum PreferredMapType: String, Codable {
    case appleMaps, googleMaps
}

struct RecentPlace: Codable, Equatable, Hashable {
    let title: String
    let town: String
}
