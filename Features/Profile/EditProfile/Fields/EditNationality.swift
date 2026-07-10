//
//  EditNationalityNew.swift
//  Scoop
//
//  Created by Art Ostin on 28/07/2025.

import SwiftUI
import FirebaseFirestore

struct OnboardingNationality: View {
    //Injected
    @Bindable var vm: OnboardingViewModel

    //Local view state
    @State private var countriesSelected: [String] = []

    var body: some View {
        GenericNationality(countriesSelected: $countriesSelected) {
            countriesSelected.toggle($0, limit: 3)
        }
        .nextButton(isValid: countriesSelected.count > 0, padding: 140) {
            vm.saveAndNextStep(kp: \.nationality, to: countriesSelected)
        }
        .onAppear {
            if let draft = vm.draftProfile {
                if !draft.nationality.isEmpty {
                    countriesSelected = draft.nationality
                }
            }
        }        
    }
}

//Powerful new way of doing arrays: I update a local copy, then assign it on dismiss. It is
struct EditNationality: View {
    let vm: EditProfileViewModel
    @State private var countriesSelected: [String]
    
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
    }
}

struct GenericNationality: View {
    //Injected
    @Binding var countriesSelected: [String]
    let onCountryTap: (String) -> ()

    //Local view state
    @State private var scrollPosition: String? = "A"
    @Namespace private var alphabetUnderline
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    private let alphabetColumns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 13)
    private let countries = CountryDataServices.shared.allCountries
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
            VStack(spacing: 0) {
                ScrollTitle(selectedCount: countriesSelected.count, totalCount: 3, title: "Nationality")
                selectedCountries
                nationalitiesView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.appCanvas)
            .overlay {alphabet}
    }
}

extension GenericNationality {
    
    private var selectedCountries: some View {
        HStack(alignment: .bottom, spacing: 0) {
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
            Spacer()
        }
        .frame(height: 35)
        .padding(.top, 10)
    }
    

    private var alphabet: some View {
        CustomScrollTab(height: 60) {
            LazyVGrid(columns: alphabetColumns, spacing: 24) {
                ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), id: \.self) { char in
                    Button {
                        withAnimation(.easeInOut) { scrollPosition = String(char) }
                    } label: {
                        Text(String(char))
                            .font(.body(20, .bold))
                            .foregroundStyle(letterColor(String(char)))
                            .overlay(alignment: .bottom) {
                                if scrollPosition == String(char) {
                                    Capsule()
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

    private func letterColor(_ letter: String) -> Color {
        guard availableLetters.contains(letter) else { return .textPlaceholder }
        return scrollPosition == letter ? .textAccent : .textPrimary
    }
    
    @ViewBuilder
    private var nationalitiesView: some View {
        let scrollAnchor = UnitPoint(x: 0.5, y: 0.12)
        ScrollView {
            ClearRectangle(size: 6)
            VStack(spacing: 48) {
                LazyVGrid(columns: columns, spacing: 36) {
                    ForEach(CountryDataServices.shared.popularCountries) { country in
                        FlagItem(country: country, countriesSelected: $countriesSelected, onCountryTap: onCountryTap)
                            .padding(.top, 3.5)
                    }
                }
                
                ForEach(groupedCountries, id: \.letter) {group in
                    VStack(spacing: 24) {
                        Text(group.letter)
                            .font(.body(32, .medium))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(group.letter)
                            .offset(x: 16)
                        
                        LazyVGrid(columns: columns, spacing: 36) {
                            ForEach(group.countries) { country in
                                FlagItem(country: country, countriesSelected: $countriesSelected, onCountryTap: onCountryTap)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
            }
            .padding(.bottom, 200)
        }
        .scrollPosition(id: $scrollPosition, anchor: scrollAnchor)
        .frame(maxHeight: .infinity, alignment: .top)
        .customScrollFade(height: 30, showFade: true)
    }
    
}

private struct FlagItem: View {
    let country: CountryData
    @Binding var countriesSelected: [String]
    let onCountryTap: (String) -> Void

    @State private var shake = false
    @State private var flashMax = false

    private var isSelected: Bool { countriesSelected.contains(country.flag) }

    var body: some View {
        VStack(spacing: 6) {
            Text(country.flag)
                .font(.system(size: 24))
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.border, lineWidth: 1)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .overlay(alignment: .topTrailing) {
                    CircleIcon(isSelected ? "minus" : "plus")
                        .offset(x: 3, y: -3)
                }
                .showShakeAnimation(bool: shake)

            if flashMax {
                Text("max 3")
                    .font(.body(12, .bold))
                    .foregroundStyle(.accent)
            } else {
                Text(country.name)
                    .font(.body(12, .medium))
                    .multilineTextAlignment(.center)
            }
        }
        .offset(y: country.name.count > 15 ? 5 : 0)
        .animation(.easeInOut(duration: 0.3), value: flashMax)
        .onTapGesture {
            withAnimation(.smooth(duration: 0.2)) {
                if countriesSelected.contains(country.flag) {
                    countriesSelected.removeAll { $0 == country.flag }
                } else if countriesSelected.count >= 3 {
                    shake.toggle()
                    flashMax = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1))
                        flashMax = false
                    }
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
            .stroke(Color.border, lineWidth: 1)
            .background(Circle().fill(Color.white))
            .frame(width: 16, height: 16)
        Image(systemName: image)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(Color.textPrimary)
    }
}


struct scrollFader: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.appCanvas, Color.clear], startPoint: .top, endPoint: .bottom
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
                    .foregroundStyle(Color.textTertiary)
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
            .shadow(.floating)
            .contentShape(Rectangle())
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
    }
}


extension Array where Element == String {
    mutating func toggle(_ s: String, limit: Int? = nil) {
        if let i = firstIndex(of: s) { remove(at: i) }
        else if limit.map({ count < $0 }) ?? true { append(s) }
    }
}

extension View {
    @ViewBuilder
    func glassRectangle(radius: CGFloat = CornerRadius.alert) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: .rect(cornerRadius: radius))
        } else {
            self
        }
    }
}

