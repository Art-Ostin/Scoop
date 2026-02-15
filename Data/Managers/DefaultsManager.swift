//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation
import FirebaseAuth

@MainActor
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

    @ObservationIgnored private var eventDrafts: [String: EventDraft] = [:]

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
        eventDrafts[profileId]
    }

    func deleteEventDraft(profileId: String) {
        eventDrafts.removeValue(forKey: profileId)
        persistEventDrafts()
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
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }

    private func decode<T: Decodable>(_ type: T.Type, for key: Keys) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private enum Keys: String, CaseIterable {
        case draftProfile
        case onboardingStep
        case recentMapSearches
        case preferredMapType
        case eventDrafts
    }
}

enum PreferredMapType: String, Codable {
    case appleMaps, googleMaps
}

struct RecentPlace: Codable, Equatable, Hashable {
    let title: String
    let town: String
}
