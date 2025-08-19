//
//  EditNationalityViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation
import SwiftUI



@Observable class EditNationalityViewModel {
    
    @Binding var vm: EditProfileViewModel
    
    init(vm: EditProfileViewModel) {
        _vm = Binding(initialValue: vm)
    }

    var selectedCountries: [String] = []
    
    let countries = CountryDataServices.shared.allCountries
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    let alphabetColumns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 13)
    
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
    
    func toggleCountry(_ country: String, dep: AppDependencies) {
        if selectedCountries.contains(country) {
            selectedCountries.removeAll(where: {$0 == country})
            Task {
                try? await vm.updateUser(values: [.nationality : FieldValue.arrayRemove([country])])
            }
        } else if selectedCountries.count < 3 {
            selectedCountries.append(country)
            Task {
                try? await vm.updateUser(values: [.nationality  : FieldValue.arrayUnion([country])])
            }
        }
    }
}

