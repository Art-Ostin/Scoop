//
//  ScoopTestTests.swift
//  ScoopTestTests
//
//  Created by Art Ostin on 28/05/2025.
//

import Testing
@testable import Scoop
import Foundation

@MainActor
struct ScoopTests {

    @Test
    func preferredMapTypePersistsAcrossReload() throws {
        let context = try DefaultsTestContext()
        defer { context.tearDown() }

        let manager = DefaultsManager(defaults: context.defaults)
        manager.updatePreferredMapType(mapType: .googleMaps)

        let reloaded = DefaultsManager(defaults: context.defaults)
        #expect(reloaded.preferredMapType == .googleMaps)
    }

    @Test
    func deleteDefaultsClearsStoredValues() throws {
        let context = try DefaultsTestContext()
        defer { context.tearDown() }

        let manager = DefaultsManager(defaults: context.defaults)
        manager.advanceOnboarding()
        manager.updateRecentMapSearches(title: "Le Rouge", town: "Montreal")
        manager.updatePreferredMapType(mapType: .appleMaps)
        manager.updateEventDraft(profileId: "profile-1", eventDraft: EventDraft(initiatorId: "u1", recipientId: "u2", type: .drink))
        manager.deleteDefaults()

        let reloaded = DefaultsManager(defaults: context.defaults)
        #expect(reloaded.onboardingStep == 0)
        #expect(reloaded.signUpDraft == nil)
        #expect(reloaded.recentMapSearches.isEmpty)
        #expect(reloaded.preferredMapType == nil)
        #expect(reloaded.fetchEventDraft(profileId: "profile-1") == nil)
    }

    @Test
    func recentSearchesAreDeduplicatedAndCapped() throws {
        let context = try DefaultsTestContext()
        defer { context.tearDown() }

        let manager = DefaultsManager(defaults: context.defaults)
        manager.updateRecentMapSearches(title: "A", town: "Montreal")
        manager.updateRecentMapSearches(title: "B", town: "Montreal")
        manager.updateRecentMapSearches(title: "C", town: "Montreal")
        manager.updateRecentMapSearches(title: "D", town: "Montreal")
        manager.updateRecentMapSearches(title: "E", town: "Montreal")
        manager.updateRecentMapSearches(title: "a", town: "montreal")

        #expect(manager.recentMapSearches.count == 4)
        #expect(manager.recentMapSearches.last == RecentPlace(title: "a", town: "montreal"))
    }
}

private struct DefaultsTestContext {
    let suiteName: String
    let defaults: UserDefaults

    init() throws {
        let suiteName = "ScoopTests.defaults.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw ContextError.invalidSuite
        }
        defaults.removePersistentDomain(forName: suiteName)
        self.suiteName = suiteName
        self.defaults = defaults
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private enum ContextError: Error {
        case invalidSuite
    }
}
