//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/08/2025.
//
import Foundation

enum ProfileType {
    case sendInvite, receivedInvite, view
}

@Observable class ProfileViewModel {
    var p: UserProfile
    var event: UserEvent?
    let dep: AppDependencies
    var profileType: ProfileType
    
    var showInvite: Bool
    
    
    init(profile: UserProfile, showInvite: Bool, dep: AppDependencies, profileType: ProfileType, event: UserEvent?) {
        self.p = profile
        self.dep = dep
        self.profileType = profileType
        self.showInvite = showInvite
        self.event = event
    }
}
