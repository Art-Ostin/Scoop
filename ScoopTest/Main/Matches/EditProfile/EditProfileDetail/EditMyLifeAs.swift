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
    
    private enum Field: Hashable { case movie, song, book }
    @State var typeSelection: [String] = ["Movie", "Song", "Book"]
    @FocusState private var focus: Field?
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 84)  {
            
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
            
            Text("My Life as a" + " \(typeSelection[selection])")
                .font(.title(32, .bold))
                .padding(.bottom, 24)
                .padding(.horizontal)
            
            TabView(selection: $selection) {
                    textField(placeholder: "What movies encapsulates 'you'", selectedOption: $selectedMovie, field: .movie)
                        .tag(0)
                    textField(placeholder: "What song encapsulates 'you' ", selectedOption: $selectedSong, field: .song)
                        .tag(1)
                    textField(placeholder: "What book encapsulates 'you' ", selectedOption: $selectedBook, field: .book)
                        .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
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
            selectedMovie = vm.draftUser.favouriteMovie ?? ""
            selectedSong = vm.draftUser.favouriteSong ?? ""
            selectedBook =  vm.draftUser.favouriteBook ?? ""
            DispatchQueue.main.async { focus = .movie }
        }
    }
}

extension EditMyLifeAs {
    
    @ViewBuilder
    private func textField(placeholder: String, selectedOption: Binding<String>, field: Field ) -> some View {
        
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
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
}
