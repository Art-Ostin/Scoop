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
    @State var text = ""
    @State var selected: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 32)  {
            VStack(spacing: 8) {
                SignUpTitle(text: "Languages Spoken")
                selectedView
            }
            VStack(spacing: 0) {
                customTextField
                languagesView
                    .customScrollFade(height: 81, showFade: true)
            }
        }
        .focusable()
        .onAppear {isFocused = true}
        .frame(maxHeight: .infinity, alignment:.top)
        .padding(.top, 48)
        .background(Color.background)
        .ignoresSafeArea(.keyboard)
    }
}

extension EditLanguages {
    
    private var customTextField: some View {
        VStack {
            TextField("Language", text: $text)
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
            FlowLayout(mode: .scrollable, items: WorldLanguages.top120Alphabetical, itemSpacing: 16) { country in
                if !selected.contains(country) {
                    OptionCell(text: country, selection: $selected, fillColour: false, isLanguages: true) { text in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected.append(text)
                        }
                    }
                }
            }
            .padding(.horizontal, -16) //Offsets default Flowlayout padding
            .offset(y: 16) //Acts as Padding with the fade at start
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            
        }
    }
    
    private var selectedView: some View {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .bottom, spacing: 24) {
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
}

