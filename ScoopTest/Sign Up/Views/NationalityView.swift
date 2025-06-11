//
//  NationalityView.swift
//  ScoopTest
//
//  Created by Art Ostin on 02/06/2025.
//

import SwiftUI

struct NationalityView: View {
    
    
    
    @Environment(ScoopViewModel.self) private var viewModel
    
    let columns = Array(repeating: GridItem(.flexible(), alignment: .center), count: 4)
    
    
    @State var addedCountries: [countryData] = []
    
    var allCountries: [countryData] = CountryDataServices.shared.allCountries
    
    
    let countries: [countryData] = [
        countryData(flag: "🇨🇦", name: "Canada"),
        countryData(flag: "🇺🇸", name: "U.S."),
        countryData(flag: "🇫🇷", name: "France"),
        countryData(flag: "🇨🇳", name: "China"),
        countryData(flag: "🇬🇧", name: "U.K."),
        countryData(flag: "🇮🇳", name: "India"),
        countryData(flag: "🇮🇷", name: "Iran"),
        countryData(flag: "🇲🇽", name: "Mexico")
    ]
    
    @State var maxCountries: Bool = false
    
    @State var conditionMet: Bool = false
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
                titleView(
                    text: "Nationality",
                    count: 3,
                    subtitle: maxCountries ? "Max 3" : "\(addedCountries.count)/3"
                )
                .padding(.top, 36)
            

            selectionFrame
            
            countrySelecter
            
            Divider()
            
            flagScrollingFrame
            
            rectangleDivider
            
            NextButton(isEnabled: conditionMet, onInvalidTap: {})
                .padding(.top, 24)
            
        }

        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    NationalityView()
        .environment(ScoopViewModel())
}


extension NationalityView {
    
    //MARK: Extension of Views
    
    private var selectionFrame: some View {
        HStack (spacing: 48) {
            
            ForEach(addedCountries, id: \.name) {country in
                Text(country.flag)
                    .overlay(alignment: .topTrailing) {
                        minusCircle
                    }
                    
                        .onTapGesture {
                            if let index = addedCountries.firstIndex(where: { $0.name == country.name }) {
                                addedCountries.remove(at: index)
                            }
                        }
            }
            .font(.system(size: 32))
            
        }
        .frame(maxWidth: . infinity, alignment: .leading)
        .frame(height: 24)
        .padding(.bottom, 24)
    }
    
    
    private var countrySelecter: some View {
        VStack(spacing: 43) {
            HStack(spacing: 0) {
                ForEach(Array("ABCDEFGHIJKLM"), id: \.self) { char in
                    Text(String(char))
                        .font(.custom("ModernEra-Bold", size: 18))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            HStack(spacing: 0) {
                ForEach(Array("NOPQRSTUVWXYZ"), id: \.self) { char in
                    Text(String(char))
                        .font(.custom("ModernEra-Bold", size: 18))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 36)
        .padding(.horizontal, -5)
    }
    
    
    private var nationalityFrame: some View {
        Text("HI")
    }
    
    
    private var flagScrollingFrame: some View {
        
        let isFirst = findingFirstCountry(country: allCountries.map {
            countryData(flag: $0.flag, name: $0.name)
        }
    )
                                            
                                            
        
        return ScrollView {
            
            VStack(spacing: 48) {
                LazyVGrid(columns: columns, spacing: 36) {
                    ForEach(countries, id: \.name) { country in
                        flagItem(
                            flag: country.flag,
                            name: country.name,
                            isSelected: addedCountries.contains(where: { $0.name == country.name }),
                            canSelect: addedCountries.count < 3 || addedCountries.contains(where: { $0.name == country.name }),
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    toggleCountry(country)
                                }
                            }
                        )
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 36) {
                    ForEach(allCountries, id: \.name) { country in
                        if isFirst.contains(country.name) {
                            Text(String(country.name.prefix(1)))
                                .font(.custom("ModernEra-Medium", size: 32))
                                .padding(.vertical, 6)
                        }
                        flagItem(
                            flag: country.flag,
                            name: country.name,
                            isSelected: addedCountries.contains(where: { $0.name == country.name }),
                            canSelect: addedCountries.count < 3 || addedCountries.contains(where: { $0.name == country.name }),
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    toggleCountry(country)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.bottom, 48)
        }
        .padding(.horizontal, -28)
        .padding(.top, 12)
        .frame(height: 380)
    }
    
    private var rectangleDivider: some View {
        
        Rectangle()
            .foregroundStyle(.black)
            .frame(width: 225, height: 1, alignment: .center)
            .frame(maxWidth: .infinity)
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
    
    func findingFirstCountry(country: [countryData]) -> Set<String> {
        Set( Dictionary(grouping: country, by: {String($0.name.prefix(1))})
            .compactMapValues { $0.first }
            .values
            .map{$0.name}
        )
    }
    
    
    
    func selectedCountry (country: countryData) {
        addedCountries.append(country)
    }
    
    func toggleCountry(_ country: countryData) {
     if let index = addedCountries.firstIndex(where: { $0.name == country.name }) {
            addedCountries.remove(at: index)
        } else if !maxCountries{
            addedCountries.append(country)
        }
        maxCountries = addedCountries.count == 3
        conditionMet = addedCountries.count > 0
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
