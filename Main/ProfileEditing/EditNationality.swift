//
//  EditNationalityNew.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.

import SwiftUI
import FirebaseFirestore

struct OnboardingNationality: View {
    
    @State private var countriesSelected: [String] = []
    @Bindable var vm: OnboardingViewModel
    
    var body: some View {
        GenericNationality(countriesSelected: $countriesSelected) {countriesSelected.toggle($0, limit: 3)}
            .nextButton(isEnabled: countriesSelected.count > 0) {
                vm.saveAndNextStep(kp: \.nationality, to: countriesSelected)
            }
    }
}

//Return to this could be a powerful new way of doing arrays: I update a local copy, then assign it on dismiss
struct EditNationality: View {
    let vm: EditProfileViewModel
    @State var countriesSelected: [String]
    
    init(vm: EditProfileViewModel) {
        self.vm = vm
        _countriesSelected = .init(initialValue: vm.draft.nationality)
    }
    
    var body: some View {
        GenericNationality(countriesSelected: $countriesSelected) { countriesSelected.toggle($0, limit: 3)
        }.onDisappear {vm.draft.nationality = countriesSelected}
    }
}

struct GenericNationality: View {
    
    @State private var shakeTicks: [String: Int] = [:]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    let alphabetColumns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 13)
    
    @Binding var countriesSelected: [String]
        
    let onCountryTap: (String) -> ()
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
    
    var body: some View {
        VStack(spacing: 36) {
            SignUpTitle(text: "Nationality", subtitle: "\(countriesSelected.count)/3")
                .padding(.top, 12)
                .padding(.horizontal, 16)
            
            selectedCountries
            
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    alphabet(proxy: proxy)
                    SoftDivider() .padding(.horizontal)
                    nationalitiesView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}

extension GenericNationality {
    
    private var selectedCountries: some View {
        HStack(spacing: 36) {
            ForEach(countriesSelected, id: \.self) {country in
                Text(country)
                    .font(.body(32))
                    .overlay(alignment: .topTrailing) {
                        CircleIcon("xmark")
                            .offset(x: 6, y: -2)
                    }
                    .onTapGesture { withAnimation(.smooth(duration: 0.2)) { onCountryTap(country)}}
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .frame(height: 0)
    }
    
    private func alphabet(proxy: ScrollViewProxy) -> some View {
        LazyVGrid(columns: alphabetColumns, spacing: 24) {
            ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), id: \.self) { char in
                Button {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(String(char), anchor: .top)
                    }
                } label: {
                    Text(String(char))
                        .font(.body(20, .bold))
                        .foregroundStyle(availableLetters.contains(String(char)) ? Color.black : Color.grayPlaceholder)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var nationalitiesView: some View {
        
        ScrollView {
            VStack(spacing: 48) {
                
                LazyVGrid(columns: columns, spacing: 36) {
                    
                    ForEach(CountryDataServices.shared.popularCountries) { country in
                        flagItem(country: country)
                            .padding(.top, 3.5)
                    }
                }
                
                ForEach(Array(groupedCountries.enumerated()), id: \.offset) { _, group in
                    VStack(spacing: 24) {
                        Text(group.letter)
                            .font(.system(size: 32))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(group.letter)
                            .offset(x: 16)
                        
                        LazyVGrid(columns: columns, spacing: 36) {
                            ForEach(group.countries) { country in
                                flagItem(country: country)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func isSelected(_ country: String) -> Bool {
        countriesSelected.contains(country)
    }
    
    
    private func flagItem(country: CountryData) -> some View {
        VStack(spacing: 6) {
            Text(country.flag)
                .font(.system(size: 24))
                .padding(6)
                .background (
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.grayPlaceholder, lineWidth: 1)
                        .fill(isSelected(country.flag) ? Color.blue : Color.clear)
                )
                .overlay( alignment: .topTrailing) {
                    CircleIcon(isSelected(country.flag) ? "minus" : "plus")
                        .offset(x: 3, y: -3)
                }
                .modifier(Shake(animatableData: CGFloat(shakeTicks[country.flag, default: 0])))
                .animation(.easeInOut(duration: 0.3), value: shakeTicks[country.flag, default: 0])

            Text(country.name)
                .font(.system(size: 12, weight: .regular))
                .multilineTextAlignment(.center)
        }
        .offset(y: country.name.count > 15 ? 5 : 0)
        .onTapGesture { withAnimation(.smooth(duration: 0.2)) {
            onCountryTap(country.flag)
            if countriesSelected.count >= 3 {
                shakeTicks[country.flag, default: 0] &+= 1
            } else {
                onCountryTap(country.flag)
            }
        }}
    }
}

func CircleIcon (_ image: String, _ fontSize: CGFloat = 8) -> some View {
    ZStack {
        Circle()
            .stroke(Color.grayPlaceholder, lineWidth: 1)
            .background(Circle().fill(Color.white))
            .frame(width: 16, height: 16)
        Image(systemName: image)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(.black)
    }
}
