//
//  EditProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation

@MainActor
@Observable class EditProfileViewModel {
    
    var cachManager: CacheManaging
    var userManager: UserManager
    var s: SessionManager
    var storageManager: StorageManaging
    
    init(cachManager: CacheManaging, s: SessionManager, userManager: UserManager, storageManager: StorageManaging) {
        self.cachManager = cachManager
        self.s = s
        self.userManager = userManager
        self.storageManager = storageManager
    }
    
    
    
    var user: UserProfile  { s.user }

    
    
    
    
    
    
    
    
    func fetchUserField<T>(_ key: KeyPath<UserProfile, T>) -> T {
        user[keyPath: key]
    }
    
    func interestIsSelected(text: String) -> Bool {
        user.interests?.contains(text) == true
    }
    
    func updateUser(values: [UserProfile.CodingKeys : Any]) async throws  {
        try await userManager.updateUser(values: values)
    }
    
    func updateUserArray(field: UserProfile.CodingKeys, value: String, add: Bool) async throws {
        try await userManager.updateUserArray(field: field, value: value, add: add)
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
    
    func fetchNationality() {
        selectedCountries = fetchUserField(\.nationality) ?? []
    }
}

