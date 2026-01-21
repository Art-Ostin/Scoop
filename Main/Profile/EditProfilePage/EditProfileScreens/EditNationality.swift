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
        GenericNationality(countriesSelected: $countriesSelected) {
            countriesSelected.toggle($0, limit: 3)
        }
        .nextButton(isEnabled: countriesSelected.count > 0, padding: 120) {
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
        GenericNationality(countriesSelected: $countriesSelected) { countriesSelected.toggle($0, limit: 3)}
        .onDisappear {
            guard countriesSelected != vm.draft.nationality else { return }
            vm.set(.nationality, \.nationality, to: countriesSelected)
        }
        .padding(.top, 24)
        .background(Color.background)
    }
}

struct GenericNationality: View {
    @State private var shakeTicks: [String: Int] = [:]
    
    @State private var scrollPosition: String? = "A"

    @Namespace private var alphabetUnderline

    
    @Binding var countriesSelected: [String]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    let alphabetColumns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 13)
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
        ScrollViewReader { proxy in
            ZStack(alignment: .topLeading) {
                ScrollTitle(selectedCount: countriesSelected.count, totalCount: 3, title: "Nationality")
                selectedCountries.zIndex(2)
                scrollFader().zIndex(1)
                nationalitiesView.zIndex(0)
                alphabet(proxy: proxy)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.background)
        }
    }
}

extension GenericNationality {
    
    private var selectedCountries: some View {
        HStack(spacing: 0) {
            ForEach(countriesSelected, id: \.self) {country in
                Text(country)
                    .font(.body(32))
                    .overlay(alignment: .topTrailing) {
                        CircleIcon("xmark")
                            .offset(x: 6, y: -2)
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.smooth(duration: 0.2)) {onCountryTap(country)}}
            }
        }
        .padding(.top, 12)
    }
    

    private func alphabet(proxy: ScrollViewProxy) -> some View {
        CustomScrollTab(height: 60) {
            LazyVGrid(columns: alphabetColumns, spacing: 24) {
                ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), id: \.self) { char in
                    Button {
                        withAnimation(.easeInOut) { scrollPosition = String(char) }
                    } label: {
                        Text(String(char))
                            .font(.body(20, .bold))
                            .foregroundStyle(availableLetters.contains(String(char)) ?
                                             (scrollPosition == String(char) ? .accent : .black) :
                                             .grayPlaceholder)
                            .overlay(alignment: .bottom) {
                                if scrollPosition == String(char) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .frame(width: 16, height: 2)
                                        .offset(y: 2)
                                        .matchedGeometryEffect(id: "underline", in: alphabetUnderline)
                                }
                            }
                    }
                }
            }
        }
        .animation(.smooth(duration: 0.25, extraBounce: 0), value: scrollPosition)
    }
    
    @ViewBuilder
    private var nationalitiesView: some View {
        
        let scrollAnchor = UnitPoint(x: 0.5, y: 0.12)

        
        ScrollView {
            ClearRectangle(size: 32)
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
                            .font(.body(32, .medium))
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
                    .scrollTargetLayout()
                }
            }
            .padding(.bottom, 200)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .scrollPosition(id: $scrollPosition, anchor: scrollAnchor)
        .padding(.top, 60)
    }
    
    private func isSelected(_ country: String) -> Bool {
        countriesSelected.contains(country)
    }
    
    private func flagItem(country: CountryData) -> some View {
        
        let shakeValue = shakeTicks[country.flag, default: 0]
        let message = "max 3"

        return VStack(spacing: 6) {
            Text(country.flag)
                .font(.system(size: 24))
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.grayPlaceholder, lineWidth: 1)
                        .fill(isSelected(country.flag) ? Color.blue : Color.clear)
                )
                .overlay(alignment: .topTrailing) {
                    CircleIcon(isSelected(country.flag) ? "minus" : "plus")
                        .offset(x: 3, y: -3)
                }
                .modifier(Shake(animatableData: shakeValue == 0 ? 0 : CGFloat(shakeValue)))
                .animation(shakeValue > 0 ? .easeInOut(duration: 0.5) : .none, value: shakeValue)
            
            if shakeValue > 0 {
                Text(message)
                    .font(.body(12, .bold))
                    .foregroundStyle(.accent)
            } else {
                Text(country.name)
                    .font(.body(12, .medium))
                    .multilineTextAlignment(.center)
            }
        }
        .offset(y: country.name.count > 15 ? 5 : 0)
        .onChange(of: shakeTicks[country.flag, default: 0]) { oldValue, newValue in
            guard newValue > 0 else { return }
            
            Task {
                try? await Task.sleep(for: .seconds(1))
                if shakeTicks[country.flag, default: 0] == newValue {
                    withAnimation { shakeTicks[country.flag] = 0 }
                }
            }
        }
        
        .onTapGesture {
            withAnimation(.smooth(duration: 0.2)) {
                if countriesSelected.contains(country.flag) {
                    countriesSelected.removeAll { $0 == country.flag }
                } else if countriesSelected.count >= 3 {
                    shakeTicks[country.flag, default: 0] += 1
                } else {
                    onCountryTap(country.flag)
                }
            }
        }
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


struct scrollFader: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.background, .clear], startPoint: .top, endPoint: .bottom
                )
            )
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
    }
}



struct ScrollTitle: View {
    let selectedCount: Int
    let totalCount: Int
    let title: String
    
    var body: some View {
        
        HStack(alignment: .bottom) {
            Text(title)
                .font(.title(32, .bold))
                .offset(y: 6)
            
            Text("\(selectedCount)/\(totalCount)")
                .font(.title(12))
            
            Spacer()
            
            if title != "Nationality" && selectedCount < 6 {
                Text("Choose at least 6")
                    .font(.body(14, .medium))
                    .foregroundStyle(Color.grayText)
            }
        }
        .padding(.horizontal)
    }
}

struct CustomScrollTab<Content: View>: View {

    private let height: CGFloat
    private let content: Content

    init(height: CGFloat, @ViewBuilder content: () -> Content) {
        self.height = height
        self.content = content()
    }
    var body: some View {
        content
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(.vertical, 16)
            .font(.body(16, .bold))
            .glassRectangle()
            .shadow(color: .black.opacity(0.1), radius: 5, y: 12)

            .contentShape(Rectangle())
            .onTapGesture {}
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
    }
}

