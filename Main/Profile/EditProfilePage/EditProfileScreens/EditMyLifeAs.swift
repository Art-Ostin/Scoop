//
//  EmbodyYou.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

enum Field: String, Hashable, CaseIterable {
    case movie, song, book
    var placeholder: String {
        switch self {
        case .movie: return "E.g. La Haine"
        case .song: return "E.g. Burial - Comafields"
        case .book: return "E.g. Candide - Voltaire"
        }
    }
}


struct EditMyLifeAs: View {
    @Bindable var vm: EditProfileViewModel
    @State var selection: Field = .movie
    @State var selectedValues: [Field: String] = [:]
    private func binding(for field: Field) -> Binding<String> {
        Binding(
            get: { selectedValues[field] ?? "" },
            set: { newValue in
                if newValue.isEmpty {
                    selectedValues[field] = ""
                } else {
                    selectedValues[field] = newValue
                }
            }
        )
    }
    
    
    
    @FocusState private var focus: Field?
    @Namespace private var tabNamespace
    
    var body: some View {
        VStack {
            TabView(selection: $selection) {
                ForEach(Field.allCases) { field in
                    textField(selectedOption: binding(for: field), field: field)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            scrollToSection
        }
        .padding(.top, 72)
        .onChange(of: selection) {updateFocus(for: selection)}
        .onChange(of: selectedValues[.movie]) { vm.set(.favouriteMovie, \.favouriteMovie, to: selectedValues[.movie]) }
        .onChange(of: selectedValues[.song]) { vm.set(.favouriteSong, \.favouriteSong, to: selectedValues[.song])}
        .onChange(of: selectedValues[.book]) { vm.set(.favouriteBook, \.favouriteBook, to: selectedValues[.book])}
        .onAppear {
            selectedValues[.movie] = vm.draft.favouriteMovie ?? ""
            selectedValues[.song] = vm.draft.favouriteSong ?? ""
            selectedValues[.song] =  vm.draft.favouriteBook ?? ""
            DispatchQueue.main.async { focus = .movie }
        }
    }
}

extension EditMyLifeAs {

    @ViewBuilder
    private func textField(selectedOption: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("Favourite" + " \(field.rawValue.capitalized)")
                .font(.title())
            VStack {
                TextField(field.placeholder, text: selectedOption)
                    .frame(maxWidth: .infinity)
                    .font(.body(24,.medium))
                    .focused($focus, equals: field)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 36)
    }

    private var scrollToSection: some View {
        CustomScrollTab(height: 20) {
            HStack(spacing: 64) {
                ForEach(Array(Field.allCases.enumerated()), id: \.offset) { index, field in
                    let isSelected = index == selection
                    Text(field.rawValue.capitalized)
                        .font(.body(17, .bold))
                        .contentShape(Rectangle())
                        .onTapGesture {withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selection = index }}
                        .foregroundStyle(isSelected ? .accent : .black)
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: 50, height: 3)
                                    .foregroundStyle(Color.accent)
                                    .offset(y: 12)
                                    .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
                            }
                        }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func updateFocus(for index: Int) {
        DispatchQueue.main.async {
            focus = Field.allCases.indices.contains(index) ? Field.allCases[index] : nil
        }
    }
}
