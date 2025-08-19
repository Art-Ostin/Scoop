//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation


@Observable class EditProfileViewModel {
    
    var cachManager: CacheManaging
    var userManager: UserManager
    var storageManager: StorageManager
    
    
    init(cachManager: CacheManaging, userManager: UserManager, storageManager: StorageManager) {
        self.cachManager = cachManager
        self.userManager = userManager
        self.storageManager = storageManager
    }
    
    
    func fetchInterests() -> [String] {
        userManager.user.interests ?? []
    }
    
    func interestIsSelected(text: String) -> Bool {
        userManager.user.interests?.contains(text) == true
    }
    
    func updateUser(values: [UserProfile.CodingKeys : Any]) async throws  {
        try await userManager.updateUser(values: values)
    }
}
