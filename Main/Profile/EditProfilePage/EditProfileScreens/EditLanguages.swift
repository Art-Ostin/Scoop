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
    @State var searchText: String = ""
    @State var selected: [String] = []
    @State var isTopOfScroll: Bool = false
    @State private var isScrolling = false

    
    private var filteredLanguages: [String] {
        let all = WorldLanguages.top120Alphabetical
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32)  {
            VStack(spacing: 8) {
                SignUpTitle(text: "Languages Spoken")
                    .padding(.horizontal, 24)
                selectedView
            }
            VStack(spacing: 0) {
                customTextField
                    .padding(.horizontal, 24)
                languagesView
                    .padding(.horizontal, 24)
            }
        }
        .focusable()
        .onAppear {isFocused = true}
        .frame(maxHeight: .infinity, alignment:.top)
        .padding(.top, 24)
        .background(Color.background)
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
    }
}

extension EditLanguages {
    
    private var customTextField: some View {
        VStack {
            TextField("Language", text: $searchText)
                .frame(maxWidth: .infinity)
                .font(.body(24))
                .font(.body(.medium))
                .focused($isFocused)
                .autocorrectionDisabled(true)
                .tint(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            RoundedRectangle(cornerRadius: 20, style: .circular)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle (Color.grayPlaceholder)
        }
    }
    
    private var languagesView: some View {
        ScrollView(.vertical) {
            FlowLayout(mode: .scrollable, items: filteredLanguages, itemSpacing: 16) { country in
                if !selected.contains(country) {
                    OptionCell(text: country, selection: $selected, fillColour: false, isLanguages: true) { text in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected.append(text)
                        }
                    }
                }
            }
            .padding(.horizontal, -16) //Offsets default Flowlayout padding
            .padding(.top, 8)
            .offset(y: 24) //Acts as Padding with the fade at start
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.background)
        .onScrollGeometryChange(for: Bool.self, of: checkIfTopOfScroll) { _, isAtTop in
            self.isTopOfScroll = isAtTop
        }
        .onScrollPhaseChange { _, newPhase in
            isScrolling = newPhase.isScrolling
        }
        .customScrollFade(height: 48, showFade: !isTopOfScroll)
    }
    
    private var selectedView: some View {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .bottom, spacing: 23) {
                        ClearRectangle(size: 1)
                        ForEach(selected, id: \.self) { selection in
                            OptionCell(text: selection, selection: $selected, fillColour: false) { text in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selected.removeAll { $0 == text }
                                }
                            }
                        }
                        ClearRectangle(size: 30)
                            .id("End Scroll")
                    }
                    .frame(height: 48)
                }
                .onChange(of: selected.count) {oldValue, newValue in
                    if newValue > oldValue {
                        Task {
                            try? await Task.sleep(nanoseconds: 50_000_000)
                            withAnimation(.easeInOut(duration: 0.4)) { proxy.scrollTo("End Scroll", anchor: .trailing) }
                        }
                    }
                }
                .scrollIndicators(.never)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
    }
    
    func checkIfTopOfScroll(_ geo: ScrollGeometry) -> Bool {
        geo.contentOffset.y + geo.contentInsets.top <= 1
    }
}
