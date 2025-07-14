//
//  NationalityView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/06/2025.
//

import SwiftUI


@Observable class NationalityViewModel  {
    
    
    var addedCountries: [CountryData] = []

    var conditionMet: Bool     = false
    var maxCountries: Bool     = false
    var scrollToIndex: [String] = []
    var isOnboarding: Bool = false
    
    let columns = Array(
      repeating: GridItem(.flexible(), alignment: .center),
      count: 4
    )
    
    let allCountries = CountryDataServices.shared.allCountries
    
    let countries: [CountryData] = [
        .init(flag: "🇨🇦", name: "Canada"),
        .init(flag: "🇺🇸", name: "U.S."),
        .init(flag: "🇫🇷", name: "France"),
        .init(flag: "🇨🇳", name: "China"),
        .init(flag: "🇬🇧", name: "U.K."),
        .init(flag: "🇮🇳", name: "India"),
        .init(flag: "🇮🇷", name: "Iran"),
        .init(flag: "🇲🇽", name: "Mexico")
      ]
}


struct NationalityView: View {
    
    @Binding var screenTracker: OnboardingContainerViewModel
    
    @State var vm = NationalityViewModel()
    
    var isOnboarding: Bool = false
    
    
    init(screenTracker: Binding<OnboardingContainerViewModel>? = nil) {
        self._screenTracker = screenTracker ?? .constant(OnboardingContainerViewModel())
    }
    
    
    
    
    var body: some View {
        
        ZStack {
            
            VStack(alignment: .leading) {
                SignUpTitle(
                    text: "Nationality",
                    count: vm.isOnboarding ? 2 : 0,
                    subtitle: "\(vm.addedCountries.count)/3"
                )
                .padding(.top, isOnboarding ? 24 : 12)
                
                selectionFrame

                flagScrollingFrame
        }
            if vm.isOnboarding {
                NextButton(isEnabled: vm.addedCountries.count > 0, onTap: {screenTracker.screen += 1})
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 540)
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    NationalityView(screenTracker: .constant(OnboardingContainerViewModel()))
}

extension NationalityView {
    
    
    private var selectionFrame: some View {
        
        HStack (spacing: 48) {
            
            ForEach(vm.addedCountries, id: \.name) {country in
                Text(country.flag)
                    .overlay(alignment: .topTrailing) {
                        minusCircle
                    }
                    .onTapGesture {
                        if let index = vm.addedCountries.firstIndex(where: { $0.name == country.name }) {
                            vm.addedCountries.remove(at: index)
                        }
                    }
            }
            .font(.system(size: 32))
        }
        .frame(maxWidth: . infinity, alignment: .leading)
        .frame(height: 24)
        .padding(.bottom, 24)
    }
    
    
    
    
    private var flagScrollingFrame: some View {
        // Compute the first occurrence of each letter
        let firstLetters = findingFirstCountry(
            country: vm.allCountries
                .map {CountryData(flag: $0.flag, name: $0.name) })
        
        return ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                // Letter selector buttons
                VStack(spacing: 43) {
                    HStack(spacing: 0) {
                        ForEach(Array("ABCDEFGHIJKLM"), id: \.self) { char in
                            Button {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(String(char), anchor: .top)
                                }
                            } label: {
                                Text(String(char))
                                    .font(.custom("ModernEra-Bold", size: 18))
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                    HStack(spacing: 0) {
                        ForEach(Array("NOPQRSTUVWXYZ"), id: \.self) { char in
                            Button {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(String(char), anchor: .top)
                                }
                            } label: {
                                Text(String(char))
                                    .font(.custom("ModernEra-Bold", size: 18))
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 36)
                .padding(.horizontal, -5)
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 48) {
                        // Pre-selected common countries
                        LazyVGrid(columns: vm.columns, spacing: 36) {
                            ForEach(vm.countries, id: \.name) { country in
                                flagItem(
                                    flag: country.flag,
                                    name: country.name,
                                    isSelected: vm.addedCountries.contains { $0.name == country.name },
                                    canSelect: vm.addedCountries.count < 3 || vm.addedCountries.contains { $0.name == country.name },
                                    onSelect: { toggleCountry(country) }
                                )
                            }
                        }
                        
                        // Full country list with letter headers
                        LazyVGrid(columns: vm.columns, spacing: 36) {
                            ForEach(vm.allCountries, id: \.name) { country in
                                if firstLetters.contains(country.name) {
                                    Text(String(country.name.prefix(1)))
                                        .font(.custom("ModernEra-Medium", size: 32))
                                        .padding(.vertical, 6)
                                        .id(String(country.name.prefix(1)))
                                }
                                flagItem(
                                    flag: country.flag,
                                    name: country.name,
                                    isSelected: vm.addedCountries.contains { $0.name == country.name },
                                    canSelect: vm.addedCountries.count < 3 || vm.addedCountries.contains { $0.name == country.name },
                                    onSelect: {toggleCountry(country) }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 48)
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, -28)
                .padding(.top, 12)
            }
        }
    }
    
    
    private var minusCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.gray, lineWidth: 1)
                .background(Circle().fill(Color.white))
                .frame(width: 16, height: 16)
            Image(systemName: "xmark")
                .font(.system(size: 10))
                .foregroundStyle(.black)
        }
        .offset(x: 6, y: 0)
    }
    
    
    
    
    
    //MARK: Extension of Funcs
    
    func findingFirstCountry(country: [CountryData]) -> Set<String> {
        Set( Dictionary(grouping: country, by: {String($0.name.prefix(1))})
            .compactMapValues { $0.first }
            .values
            .map{$0.name}
        )
    }
    
    func selectedCountry (country: CountryData) {
        vm.addedCountries.append(country)
    }
    
    func toggleCountry(_ country: CountryData) {
        if let index = vm.addedCountries.firstIndex(where: { $0.name == country.name }) {
            vm.addedCountries.remove(at: index)
        } else if !vm.maxCountries{
            vm.addedCountries.append(country)
        }
        vm.maxCountries = vm.addedCountries.count == 3
        vm.conditionMet = vm.addedCountries.count > 0
    }
}




struct flagItem: View {
    
    let flag: String
    
    let name: String
    
    let isSelected: Bool
    
    let canSelect: Bool
    
    let onSelect: () -> Void
    
    var body: some View {
        
        Button {
            withAnimation(.easeInOut(duration: 0.01)) {
                if canSelect {
                    onSelect()
                }
            }
            
        } label: {
            VStack {
                ZStack(alignment: .topTrailing) {
                    
                    flagBox
                    
                    addCircle
                }
                nameSection
            }
        }
    }
}

extension flagItem {
    
    private var flagBox: some View  {
        Text(flag)
            .font(.system(size: 24))
            .frame(width: 35, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? (Color(red: 0.9, green: 0.91, blue: 1)) : Color.white)
                    .stroke(isSelected ?  (Color(red: 0.9, green: 0.91, blue: 1)) : Color.gray.opacity(0.6), lineWidth: 1)
                    .frame(width: 35, height: 35)
                    .shadow(color: isSelected ? .black.opacity(0.15): .clear, radius: 2, x: 0, y: 2)
            )
    }
    
    private var addCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.gray, lineWidth: 1)
                .background(Circle().fill(Color.white))
                .frame(width: 16, height: 16)
            
            Image(systemName: isSelected ? "minus" : "plus")
                .font(.system(size: 10))
                .foregroundStyle(.black)
        }
        .offset(x: 6, y: 0)
    }
    
    private var nameSection: some View {
        Text(name)
            .font(.custom("ModernEra-Medium", size: 10))
            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
            .offset(y: -2)
            .lineLimit(3)
            .frame(width: 75)
            .multilineTextAlignment(.center)
            .fixedSize()
    }
}
