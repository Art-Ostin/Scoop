//
//  EditMyMedia.swift
//  Scoop
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

enum MediaField: String, CaseIterable, Hashable, Identifiable {
    case movie, song, book
    var id: Self { self }
    
    var title: String { rawValue.capitalized }
    
    var placeholder: String {
        switch self {
        case .movie: "E.g. La Haine"
        case .song:  "E.g. Burial - Comafields"
        case .book:  "E.g. Candide - Voltaire"
        }
    }
}


struct EditMyMedia: View {
    
    //Injected
    @Bindable var vm: EditProfileViewModel

    //Local view state
    @State private var selection: MediaField? = .movie
    @State private var selectedValues: [MediaField: String] = [:]

    @FocusState private var focus: MediaField?
    @Namespace private var tabNamespace


    //Writes through to the draft as it goes, so only the edited field is ever set
    private func binding(for field: MediaField) -> Binding<String> {
        .init(
            get: { selectedValues[field, default: ""] },
            set: { new in
                selectedValues[field] = new
                store(new, in: field)
            }
        )
    }

    private func stored(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        HorizontalScrollView(progress: .constant(0)) {
            ForEach(MediaField.allCases) { field in
                page(for: field)
            }
        }
        .scrollPosition(id: $selection)
        .scrollDismissesKeyboard(.never) //Pins the mapping across OS versions: the SDK's prose and its behaviour disagree on the default
        .safeAreaInset(edge: .bottom) {selectionMenu}

        .task(id: selection) { focusSettledPage() }
        .onAppear {loadValues()}
    }
}

//Tab bar
extension EditMyMedia {

    private var selectionMenu: some View {
        CustomScrollTab(height: 20) {
            HStack(spacing: Spacing.xxxl) {
                ForEach(MediaField.allCases) { field in
                    text(field)
                }
            }
            .animation(.toggle, value: selection)
        }
        .padding(.horizontal, Spacing.margin)
    }
    
    private func text(_ field: MediaField) -> some View {
        let isSelected = field == selection
        return Text(field.title)
            .font(.body(17, .bold))
            .foregroundStyle(isSelected ? .accent : .textPrimary)
            .contentShape(Rectangle())
            .shrinkPress { selection = field }
            .overlay(alignment: .bottom) { if isSelected { underLine } }
    }
    
    private var underLine: some View {
        Capsule()
            .frame(width: 50, height: 3)
            .offset(y: 8)
            .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
            .foregroundStyle(.accent)
    }
}

//Pages
extension EditMyMedia {
    private func page(for field: MediaField) -> some View {
        VStack(alignment: .leading, spacing: Spacing.titleGap) {
            Text("Favourite \(field.title)")
                .font(.title())
            
            UnderlinedTextField(text: binding(for: field), placeholder: field.placeholder)
                .focused($focus, equals: field)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, Spacing.clearance)
        .padding(.horizontal, Spacing.xl)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .containerRelativeFrame(.horizontal)
    }
}

//Functions required
extension EditMyMedia {
    
    //Moves the keyboard to the page the pager has landed on.
    //`.scrollPosition(id:)` reports nil for the whole flight and the landed page at the end, so
    //this only ever runs at rest — that gate, not a resign-and-wait, is what stops a focus change
    //from making UIKit scroll the field into view and strand the pager half-way. Focus is handed
    //straight from one mounted field to the next: `becomeFirstResponder` resigns the old one
    //inside its own bracket, so first responder is never vacant and the keyboard re-targets
    //instead of collapsing. Never write `focus = nil` here — that is what made it drop.
    //`.task`'s hop is load-bearing: it lands the write after the tab bar's instant jump has
    //committed its offset.
    private func focusSettledPage() {
        guard let selection, focus != selection else { return }
        focus = selection
    }
    
    private func store(_ text: String, in field: MediaField) {
        switch field {
        case .movie: vm.set(.favouriteMovie, \.favouriteMovie, to: stored(text))
        case .song:  vm.set(.favouriteSong,  \.favouriteSong,  to: stored(text))
        case .book:  vm.set(.favouriteBook,  \.favouriteBook,  to: stored(text))
        }
    }
    
    private func loadValues() {
        selectedValues = [
            .movie: vm.draft.favouriteMovie ?? "",
            .song:  vm.draft.favouriteSong  ?? "",
            .book:  vm.draft.favouriteBook  ?? ""
        ]
    }
    
}
