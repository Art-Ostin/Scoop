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
    @Bindable var vm: EditProfileViewModel

    @State private var selection: MediaField? = .movie
    @State private var selectedValues: [MediaField: String] = [:]

    @FocusState private var focus: MediaField?
    @Namespace private var tabNamespace

    private func binding(for field: MediaField) -> Binding<String> {
        .init(
            get: { selectedValues[field, default: ""] },
            set: { selectedValues[field] = $0 }
        )
    }

    //A blank box means "not set", not an empty string: the model stores these as String? and every
    //display site unwraps with `if let`, so "" would render an icon with no text beside it.
    private func stored(_ field: MediaField, in values: [MediaField: String]) -> String? {
        let trimmed = values[field]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    var body: some View {
        HorizontalScrollView(progress: .constant(0)) {
            ForEach(MediaField.allCases) { field in
                page(for: field)
                    .containerRelativeFrame([.horizontal, .vertical])
                    .id(field)
            }
        }
        .scrollPosition(id: $selection)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            tabs
        }
        //Cancels itself when selection moves again, so a fast swipe can't leave a stale timer
        //behind that yanks focus onto a page the user has already left.
        .task(id: selection) {
            if focus != nil {                                   //A page change, not first appearance
                focus = nil                                     //Every page stays mounted: resign first or the old field eats the keystrokes
                try? await Task.sleep(for: .milliseconds(300))  //Delay removes bug of half swiping for user
                guard !Task.isCancelled else { return }
            }
            focus = selection
        }
        .onChange(of: selectedValues) { _, values in
            vm.set(.favouriteMovie, \.favouriteMovie, to: stored(.movie, in: values))
            vm.set(.favouriteSong,  \.favouriteSong,  to: stored(.song,  in: values))
            vm.set(.favouriteBook,  \.favouriteBook,  to: stored(.book,  in: values))
        }
        .onAppear {
            selectedValues = [
                .movie: vm.draft.favouriteMovie ?? "",
                .song:  vm.draft.favouriteSong  ?? "",
                .book:  vm.draft.favouriteBook  ?? ""
            ]
        }
    }
}

//Tab bar
extension EditMyMedia {

    private var tabs: some View {
        CustomScrollTab(height: 20) {
            HStack(spacing: Spacing.xxxl) {
                ForEach(MediaField.allCases) { field in
                    let isSelected = field == selection

                    Text(field.title)
                        .font(.body(17, .bold))
                        .contentShape(Rectangle())
                        .onTapGesture { selection = field }
                        .foregroundStyle(isSelected ? .accent : .textPrimary)
                        .overlay(alignment: .bottom) {
                            if isSelected {
                                Capsule()
                                    .frame(width: 50, height: 3)
                                    .offset(y: 8)
                                    .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
                                    .foregroundStyle(.accent)
                            }
                        }
                }
            }
            //Keyed off selection on a stable ancestor so a swipe animates the underline too —
            //a withAnimation inside the tap only ever covered the tap.
            .animation(.toggle, value: selection)
        }
        .padding(.horizontal, Spacing.margin)
    }
}

//Pages
extension EditMyMedia {

    private func page(for field: MediaField) -> some View {
        VStack(alignment: .leading, spacing: Spacing.titleGap) {
            Text("Favourite \(field.title)")
                .font(.title())
            
            VStack {
                TextField(field.placeholder, text: binding(for: field))
                    .frame(maxWidth: .infinity)
                    .font(.body(24,.medium))
                    .focused($focus, equals: field)
                    .autocorrectionDisabled(true)
                    .tint(.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Capsule()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundStyle (Color.textPlaceholder)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.clearance)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
