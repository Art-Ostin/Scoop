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
    
    func fetchUserField<T>(_ key: KeyPath<UserProfile, T>) -> T {
        userManager.user[keyPath: key]
    }
    
    func interestIsSelected(text: String) -> Bool {
        userManager.user.interests?.contains(text) == true
    }
    
    func updateUser(values: [UserProfile.CodingKeys : Any]) async throws  {
        try await userManager.updateUser(values: values)
    }
    
    func updateUserArray(field: UserProfile.CodingKeys, value: String, add: Bool) async throws {
        try await userManager.updateUserArray(field: field, value: value, add: add)
    }
    
    func fetchUser() -> UserProfile {
        userManager.user
    }
    
    //Nationality Functionality
    var selectedCountries: [String] = []
    let countries = CountryDataServices.shared.allCountries
    var availableLetters: Set<String> {
        Set(countries.map { String($0.name.prefix(1)) })
    }
    var groupedCountries: [(letter: String, countries: [CountryData])] {
        let groups = Dictionary(grouping: countries, by: { String($0.name.prefix(1)) })
        let sortedKeys = groups.keys.sorted()
        return sortedKeys.map { key in
            (key, groups[key]!.sorted { $0.name < $1.name })
        }
    }
    func isSelected(_ country: String) -> Bool {
        selectedCountries.contains(country)
    }
    func toggleCountry(_ country: String) {
        if selectedCountries.contains(country) {
            selectedCountries.removeAll(where: {$0 == country})
            Task { try? await updateUserArray(field: .nationality, value: country, add: false)}
        } else if selectedCountries.count < 3 {
            selectedCountries.append(country)
            Task {try? await updateUserArray(field: .nationality, value: country, add: true) }
        }
    }
}

