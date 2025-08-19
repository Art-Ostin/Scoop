//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/08/2025.
//
import Foundation
import SwiftUI


@Observable class ProfileViewModel {
    
    let cacheManager: CacheManaging
    let profileModel: ProfileModel
    
    var showInvite: Bool = false
    
    init(profileModel: ProfileModel, cacheManager: CacheManaging) {
        self.profileModel = profileModel
        self.cacheManager = cacheManager
    }
    
    func loadImages() async -> [UIImage] {
        return await cacheManager.loadProfileImages([profileModel.profile])
    }
}
