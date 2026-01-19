//
//  EmbodyYou.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct EditMyLifeAs: View {
    @Bindable var vm: EditProfileViewModel
    @State var selection: Int = 0
    
    
    @State var selectedMovie: String = ""
    @State var selectedSong: String = ""
    @State var selectedBook: String = ""
    
    private enum Field: String, Hashable, CaseIterable { case movie, song, book }
    @FocusState private var focus: Field?
    @Namespace private var tabNamespace
    
    
    var body: some View {
        VStack {
            TabView(selection: $selection) {
                textField(placeholder: "E.g. La Haine", selectedOption: $selectedMovie, field: .movie)
                    .tag(0)
                textField(placeholder: "E.g. Comafields - Burial", selectedOption: $selectedSong, field: .song)
                    .tag(1)
                textField(placeholder: "E.g. Candide - Voltaire ", selectedOption: $selectedBook, field: .book)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            
            scrollToSection
            
        }
        .onChange(of: selection) {
            if selection == 0 {
                focus = .movie
            } else if selection == 1 {
                focus = .song
            } else {
                focus = .book
            }
        }
        .onChange(of: selectedMovie) { vm.set(.favouriteMovie, \.favouriteMovie, to: selectedMovie) }
        .onChange(of: selectedSong) { vm.set(.favouriteSong, \.favouriteSong, to: selectedSong)}
        .onChange(of: selectedBook) { vm.set(.favouriteBook, \.favouriteBook, to: selectedBook)}
        .onAppear {
            selectedMovie = vm.draft.favouriteMovie ?? ""
            selectedSong = vm.draft.favouriteSong ?? ""
            selectedBook =  vm.draft.favouriteBook ?? ""
            DispatchQueue.main.async { focus = .movie }
        }
    }
}

extension EditMyLifeAs {

    @ViewBuilder
    private func textField(placeholder: String, selectedOption: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 36) {
            Text("Favourite" + " \(field.rawValue.capitalized)")
                .font(.title())
            VStack {
                TextField(placeholder, text: selectedOption)
                    .frame(maxWidth: .infinity)
                    .font(.body(24))
                    .focused($focus, equals: field)
                
                RoundedRectangle(cornerRadius: 20, style: .circular)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundStyle (Color(red: 0.48, green: 0.48, blue: 0.48))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var scrollToSection: some View {
        CustomScrollTab(height: 20) {
            HStack(spacing: 64) {
                ForEach(Array(Field.allCases.enumerated()), id: \.offset) { index, field in
                    let isSelected = index == selection
                    Text(field.rawValue.capitalized)
                        .font(.body(17, .bold))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selection = index }
                        }
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
            .padding(.horizontal)
        }
    }
}



/*
 HStack(spacing: 60) {
     ForEach(typeSelection.indices, id: \.self) { index in
         let text = typeSelection[index]
         Text(text)
             .foregroundStyle(selection == index ? .accent : .primary)
             .font(.body(16, selection == index ? .bold : .medium))
     }
 }
 .frame(maxWidth: .infinity, alignment: .center)
 .padding(.top)

 */


/*
 
 
 
 
 ForEach(typeSelection.indices, id: \.self) { index in
     let isSelected = index == selection
     Text(typeSelection[index])
         .contentShape(Rectangle())
         .onTapGesture {
             withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {selection = index}
         }
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
}
}

 */
