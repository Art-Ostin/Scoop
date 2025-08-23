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
    
    var draftUser: UserProfile
    
    init(cachManager: CacheManaging, s: SessionManager, userManager: UserManager, storageManager: StorageManaging, draftUser: UserProfile) {
        self.cachManager = cachManager
        self.s = s
        self.userManager = userManager
        self.storageManager = storageManager
        self.draftUser = draftUser
    }
    
    var user: UserProfile { s.user }
    
    
    //For String Updates
    var updatedFields: [UserProfile.CodingKeys : Any] = [:]
    
    func set<T>(_ key: UserProfile.CodingKeys, _ kp: WritableKeyPath<UserProfile, T>,  to value: T) {
        draftUser[keyPath: kp] = value
        updatedFields[key] = value
    }
    
    var updatedFieldsArray: [(field: UserProfile.CodingKeys, value: String, add: Bool)] = []
    
    func setAray(_ key: UserProfile.CodingKeys, _ kp: WritableKeyPath<UserProfile, [String]?>,  to element: String, add: Bool) {
        if add == true {
            draftUser[keyPath: kp]?.append(element)
        } else {
            draftUser[keyPath: kp]?.removeAll(where: {$0 == element})
            print("function called")
        }
        updatedFieldsArray.append((field: key, value: element, add: add))
        print("Added from Array")
        print(updatedFieldsArray)
    }
    
    
    
    func saveUserArray() async throws {
        guard !updatedFieldsArray.isEmpty else { return }
        for (field, value, add) in updatedFieldsArray {
            try await userManager.updateUserArray(field: field, value: value, add: add)
        }
        await s.loadUser()
        print("savedToUserArray")
    }
    
    func saveUser() async throws {
        guard !updatedFields.isEmpty else { return }
        try await userManager.updateUser(values: updatedFields)
        await s.loadUser()
    }
    
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
        selectedCountries = draftUser.nationality ?? []
    }
}


