//
//  ProfileInvite.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/08/2025.
//

import Foundation
@preconcurrency import FirebaseFirestore

//User Facing Information about profiles
struct PendingProfile: Identifiable, Equatable, Hashable {
    let profile: UserProfile
    let image: UIImage
    var id: String { profile.id}
    
    static func == (lhs: PendingProfile, rhs: PendingProfile) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
