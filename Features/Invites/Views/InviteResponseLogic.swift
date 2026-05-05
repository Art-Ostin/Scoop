//
//  InviteResponseLogic.swift
//  Scoop
//
//  Created by Art Ostin on 27/04/2026.
//

import SwiftUI

extension InvitesContainer {
    
    func respondToProfile(respondType: ProfileResponse, profileId: String) async throws {
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        ui.respondedToProfile = respondType
        try? await Task.sleep(for: .milliseconds(550))
        ui.selectedProfile = nil
        try await respondToProfileAction(respondType: respondType, profileId: profileId)
        try? await minDelay
        ui.respondedToProfile = nil
        if respondType == .accepted {
            selectedTab.wrappedValue = .events
        }
    }
    
    private func respondToProfileAction(respondType: ProfileResponse, profileId: String) async throws {
        switch respondType {
        case .accepted:  try await vm.accept(profileId: profileId)
        case .newTime:   try await vm.sendNewTime(profileId: profileId)
        case .newInvite: try await vm.sendNewEvent(profileId: profileId)
        case .decline:   try await vm.decline(profileId: profileId)
        }
    }
}
