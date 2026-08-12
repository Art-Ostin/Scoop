//
//  EditLanguages.swift
//  Scoop
//
//  Created by Art Ostin on 18/01/2026.
//

import SwiftUI
import SwiftUIFlowLayout

struct EditLanguages: View {
    @Bindable var vm: EditProfileViewModel
    @FocusState var isFocused: Bool
    @State private var searchText: String = ""
    @State private var selected: [String]
    @State private var isTopOfScroll: Bool = false
    @State private var isScrolling = false
    @State private var selectedScrollPos = ScrollPosition()

    private let maxCount = 5
    
    private var filteredLanguages: [String] {
        let all = WorldLanguages.top120Alphabetical
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
    
    init(vm: EditProfileViewModel) {
        self.vm = vm
        _selected = .init(wrappedValue: vm.draft.languages)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl)  {
            VStack(spacing: Spacing.xs) {
                SignUpTitle(text: "I Speak")
                    .padding(.horizontal, Spacing.margin)
                selectedView
                    .padding(.top, 12)
            }
            VStack(spacing: 0) {
                UnderlinedTextField(text: $searchText, placeholder: "Language")
                    .focused($isFocused)
                    .padding(.horizontal, Spacing.margin)
                languagesView
                    .padding(.horizontal, Spacing.margin)
            }
        }
        .focusable()
        .onAppear {isFocused = true}
        .frame(maxHeight: .infinity, alignment:.top)
        .padding(.top, Spacing.xxxl)
        .background(Color.appCanvas)
        .ignoresSafeArea(.keyboard)
        .onChange(of: isScrolling) {
            if isScrolling {
                isFocused = false
            }
        }
        .onChange(of: selected.count) { oldValue, newValue in
            if oldValue < newValue {
                searchText = ""
            }
        }
        .onDisappear {
            guard selected != vm.draft.languages else {
                return
            }
            vm.set(.languages, \.languages, to: selected)
        }
    }
}

extension EditLanguages {
    
    private var languagesView: some View {
        ScrollView(.vertical) {
            FlowLayout(mode: .scrollable, items: filteredLanguages, itemSpacing: 16) { country in
                if !selected.contains(country) {
                    OptionCell(
                        text: country,
                        maxCount: maxCount,
                        selection: $selected,
                        style: .outlined,
                        isLanguages: true
                    )
                }
            }
            .padding(.horizontal, -16) //Offsets default Flowlayout padding
            .padding(.top, Spacing.xs)
            .offset(y: 24) //Acts as Padding with the fade at start
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCanvas)
        .onScrollGeometryChange(for: Bool.self, of: checkIfTopOfScroll) { _, isAtTop in
            self.isTopOfScroll = isAtTop
        }
        .onScrollPhaseChange { _, newPhase in
            isScrolling = newPhase.isScrolling
        }
        .customScrollFade(height: 48, showFade: !isTopOfScroll)
    }
    
    private var selectedView: some View {
            ScrollView(.horizontal) {
                HStack(alignment: .bottom, spacing: Spacing.lg) {
                    ForEach(selected, id: \.self) { selection in
                        OptionCell(text: selection, selection: $selected, style: .outlined)
                    }
                }
                .padding(.top, Spacing.xs) //Geometry: headroom for the xmark badge, which overhangs its chip by 6
                .frame(minHeight: 48, alignment: .top) //holds the row open while nothing is selected
            }
            .contentMargins(.all, EdgeInsets(top: 0, leading: Spacing.lg, bottom: 0, trailing: Spacing.xxl), for: .scrollContent)
            .scrollPosition($selectedScrollPos)
            .onChange(of: selected.count) {oldValue, newValue in
                if newValue > oldValue {
                    Task {
                        try? await Task.sleep(nanoseconds: 50_000_000)
                        withAnimation(.move) { selectedScrollPos.scrollTo(edge: .trailing) }
                    }
                }
            }
            .scrollIndicators(.never)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func checkIfTopOfScroll(_ geo: ScrollGeometry) -> Bool {
        geo.contentOffset.y + geo.contentInsets.top <= 1
    }
}
