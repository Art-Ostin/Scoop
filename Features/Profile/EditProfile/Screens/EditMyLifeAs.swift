//
//  EmbodyYou.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

enum Field: String, CaseIterable, Hashable, Identifiable {
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


struct EditMyLifeAs: View {
    @Bindable var vm: EditProfileViewModel

    @State private var selection: Field = .movie
    @State private var selectedValues: [Field: String] = [:]

    @FocusState private var focus: Field?
    @Namespace private var tabNamespace

    private func binding(for field: Field) -> Binding<String> {
        .init(
            get: { selectedValues[field, default: ""] },
            set: { selectedValues[field] = $0 }
        )
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(Field.allCases) { page(for: $0).tag($0)}
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            tabs
        }
        .onChange(of: selection) { _, new in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focus = new } //Delay removes bug of half swiping for user
        }
        .onChange(of: selectedValues) { _, values in
            vm.set(.favouriteMovie, \.favouriteMovie, to: values[.movie])
            vm.set(.favouriteSong,  \.favouriteSong,  to: values[.song])
            vm.set(.favouriteBook,  \.favouriteBook,  to: values[.book])
        }
        .onAppear {
            selectedValues = [
                .movie: vm.draft.favouriteMovie ?? "",
                .song:  vm.draft.favouriteSong  ?? "",
                .book:  vm.draft.favouriteBook  ?? ""
            ]
            DispatchQueue.main.async { focus = selection }
        }
    }
}

extension EditMyLifeAs {

         var tabs: some View {
            CustomScrollTab(height: 20) {
                HStack(spacing: 64) {
                    ForEach(Field.allCases) { field in
                        let isSelected = field == selection

                        Text(field.title)
                            .font(.body(17, .bold))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selection = field
                                }
                            }
                            .foregroundStyle(isSelected ? .accent : .primary)
                            .overlay(alignment: .bottom) {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 16)
                                        .frame(width: 50, height: 3)
                                        .offset(y: 8)
                                        .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
                                        .foregroundStyle(.accent)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    
    func page(for field: Field) -> some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("Favourite \(field.title)")
                .font(.title())
            
            VStack {
                TextField(field.placeholder, text: binding(for: field))
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
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 36)
        .padding(.top, 96)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
