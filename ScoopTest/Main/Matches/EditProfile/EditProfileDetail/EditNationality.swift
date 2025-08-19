//
//  EditNationalityNew.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.

import SwiftUI
import FirebaseFirestore

struct EditNationality: View {
    
    @Environment(\.flowMode) private var mode
    @Binding var vm: EditProfileViewModel
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    let alphabetColumns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 13)
    var body: some View {
        
        VStack(spacing: 36) {
            SignUpTitle(text: "Nationality", subtitle: "\(vm.selectedCountries.count)/3")
                .padding(.top, 12)
            
            selectedCountries
            
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    alphabet(proxy: proxy)
                    SoftDivider() .padding(.horizontal)
                    ZStack {
                        nationalitiesView
                        nextButton
                    }
                }
            }
        }
        .onAppear { vm.fetchNationality() }
        .flowNavigation()
    }
}


extension EditNationality {
    
    private var selectedCountries: some View {
        HStack(spacing: 36) {
            ForEach(vm.selectedCountries, id: \.self) {country in
                Text(country)
                    .font(.body(32))
                    .overlay(alignment: .topTrailing) {
                        circleIcon("xmark")
                            .offset(x: 6, y: -2)
                    }
                    .onTapGesture {
                        withAnimation(.smooth(duration: 0.2)) {vm.toggleCountry(country)}
                    }
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
                        .foregroundStyle(vm.availableLetters.contains(String(char)) ? Color.black : Color.grayPlaceholder)
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
                
                ForEach(vm.groupedCountries, id: \.letter) { group in
                    VStack(spacing: 24) {
                        Text(group.letter)
                            .font(.body(32))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(group.letter)
                            .offset(x: 16)
                        
                        LazyVGrid(columns: vm.columns, spacing: 36) {
                            ForEach(group.countries) { country in
                                flagItem(country: country)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var nextButton: some View {
        if case .onboarding(_, let advance) = mode {
            NextButton(isEnabled: vm.selectedCountries.count > 0) {
                withAnimation { advance()}
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
            .padding(.top, 360)
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
                    circleIcon(vm.isSelected(country.flag) ? "minus" : "plus")
                        .offset(x: 3, y: -3)
                }
            Text(country.name)
                .font(.body(12, .regular))
                .multilineTextAlignment(.center)
        }
        .offset(y: country.name.count > 15 ? 5 : 0)
        .onTapGesture {
            withAnimation(.smooth(duration: 0.2)) { vm.toggleCountry(country.flag)}
        }
    }
    
    private func circleIcon (_ image: String, _ fontSize: CGFloat = 8) -> some View {
        ZStack {
            Circle()
                .stroke(Color.grayPlaceholder, lineWidth: 1)
                .background(Circle().fill(Color.white))
                .frame(width: 16, height: 16)
            Image(systemName: image)
                .font(.body(fontSize, .bold))
                .foregroundStyle(.black)
        }
    }
}

