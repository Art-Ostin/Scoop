//
//  EditNationality2.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/07/2025.
//

import SwiftUI

@MainActor
@Observable class EditNationalityViewModel {
    
    var selectedCountries: [String] = EditProfileViewModel.instance.user?.nationality ?? []
    let countries = CountryDataServices.shared.allCountries
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    func findingFirstCountry(country: [CountryData]) -> Set<String> {
        Set(Dictionary(grouping: country, by: {String($0.name.prefix(1))})
            .compactMapValues {$0.first }
            .values
            .map{$0.name}
        )
    }
    func isSelected(_ country: String) -> Bool {
        selectedCountries.contains(country)
    }
    
    let columns2 = Array(repeating: GridItem(.flexible(), spacing: 5), count: 13)
    
    let firestoreManager = EditProfileViewModel.instance
    
    private func isSelected(country: CountryData) -> Bool {
        return firestoreManager.user?.nationality?.contains(country.flag) == true
    }
    
    func addAndRemoveCountry(_ country: String) {
        let currentlyInFirebase = firestoreManager.user?.nationality?.contains(country) == true
        if currentlyInFirebase {
            firestoreManager.removeNationality(nationality: country)
        } else if selectedCountries.count < 3 {
            firestoreManager.updateNationality(nationality: country)
        }
    }
}

struct EditNationality: View {
    
    var isOnboarding: Bool
    
    
    @State var vm = EditNationalityViewModel()
    
    @Binding var screenTracker: OnboardingViewModel
    
    
    init(isOnboarding: Bool = false, screenTracker: Binding<OnboardingViewModel>? = nil) {
        self.isOnboarding = isOnboarding
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
    }
    
    
    var body: some View {
        
        let firstLetters = vm.findingFirstCountry(
            country: vm.countries
                .map {CountryData(flag: $0.flag, name: $0.name) })
        VStack(spacing: 36) {
            
            SignUpTitle(text: "Nationality",
                        subtitle: "\(vm.selectedCountries.count)/3")
            HStack(spacing: 36) {
                ForEach(vm.selectedCountries, id: \.self) {country in
                    Text(country)
                        .font(.body(32))
                        .overlay(alignment: .topTrailing) {
                            crossButton
                                .offset(x: 6, y: -2)
                        }
                        .onTapGesture {
                            withAnimation(.smooth(duration: 0.2)) {
                                vm.selectedCountries.removeAll(where: {$0 == country})
                                vm.firestoreManager.removeNationality(nationality: country)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .frame(height: 0)
            
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    LazyVGrid(columns: vm.columns2, spacing: 24) {
                        ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), id: \.self) {char in
                            Button {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(String(char), anchor: .top)
                                }
                            } label: {
                                Text(String(char))
                                    .font(.body(20, .bold))
                                    .foregroundStyle(char == "W" || char == "X" ? Color.grayPlaceholder : Color.black)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    SoftDivider()
                        .padding(.horizontal)

                    ZStack {
                        ScrollView {
                            
                            VStack(spacing: 72) {
                                LazyVGrid(columns: vm.columns, spacing: 48) {
                                    
                                    ForEach(CountryDataServices.shared.popularCountries) { country in
                                        flagItem(country: country)
                                            .padding(.top, 3.5)
                                    }
                                }
                                
                                LazyVGrid(columns: vm.columns, spacing: 48) {
                                    ForEach(vm.countries) { country in
                                        if firstLetters.contains(country.name) {
                                            Text(String(country.name.prefix(1)))
                                                .font(.body(32))
                                                .gridCellColumns(4)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                .id(String(country.name.prefix(1)))
                                            
                                        }
                                        flagItem(country: country)
                                    }
                                }
                            }
                        }
                        if isOnboarding {
                            NextButton(isEnabled: vm.selectedCountries.count > 0, onTap: {
                                withAnimation {
                                    screenTracker.screen += 1
                                }
                            })
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding()
                            .padding(.top, 360)
                            
                        }
                    }
                }
            }
        }
        .customNavigation(isOnboarding: isOnboarding)
    }
}


#Preview {
    EditNationality(isOnboarding: true)
}

extension EditNationality {
    
    private var crossButton: some View {
        ZStack{
            Circle()
                .stroke(Color.grayPlaceholder, lineWidth: 1)
                .background(Circle().fill(Color.white))
                .frame(width: 16, height: 16)
            Image(systemName: "xmark")
                .font(.body(8, .bold))
                .foregroundStyle(.black)
        }
    }
    
    private func plusButton(_ country: String) -> some View {
        ZStack{
            Circle()
                .stroke(Color.grayPlaceholder, lineWidth: 1)
                .background(Circle().fill(Color.white))
                .frame(width: 16, height: 16)
            Image(systemName: vm.isSelected(country) ? "minus" :"plus")
                .font(.body(12, .medium))
                .foregroundStyle(.black)
        }
    }
    
    private func flagItem(country: CountryData) -> some View {
        VStack(spacing: 6) {
            Text(country.flag)
                .font(.body(24))
                .padding(6)
                .background (
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.grayPlaceholder, lineWidth: 1)
                        .fill(vm.isSelected(country.flag) ? Color.blue : Color.clear)
                )
                .overlay( alignment: .topTrailing) {
                    plusButton(country.flag)
                        .offset(x: 3, y: -3)
                }
            Text(country.name)
                .font(.body(12, .regular))
                .multilineTextAlignment(.center)
        }
        .offset(y: country.name.count > 15 ? 5 : 0)
        .onTapGesture {
            withAnimation(.smooth(duration: 0.2)) {
                if vm.isSelected(country.flag) {
                    vm.selectedCountries.removeAll(where: {$0 == country.flag})
                    vm.firestoreManager.removeNationality(nationality: country.flag)
                } else if vm.selectedCountries.count < 3 {
                    vm.selectedCountries.append(country.flag)
                    vm.firestoreManager.updateNationality(nationality: country.flag)
                }
            }
        }
    }
}
