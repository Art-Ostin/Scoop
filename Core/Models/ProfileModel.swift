//
//  ProfileInvite.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/08/2025.
//

import Foundation
import UIKit

struct ProfileModel: Identifiable, Equatable {
    var event: UserEvent?
    var profile: UserProfile
    var image: UIImage?
    var id: String { profile.id}
    
    static func == (lhs: ProfileModel, rhs: ProfileModel) -> Bool {
        lhs.id == rhs.id
    }
}


