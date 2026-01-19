//
//  EditFavouriteMedia.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.
//

import SwiftUI

struct EditFavouriteMedia: View {
    
    @FocusState var movieFocus: Bool
    @FocusState var songFocus: Bool
    @FocusState var bookFocus: Bool
    
    @State var movie: String = ""
    @State var song: String = ""
    @State var book: String = ""

    
    var body: some View {
        
        VStack(spacing: 48) {
            customTextField(title: "Favourite Movie", text: $movie, focus: $movieFocus)
            customTextField(title: "Favourite Song", text: $song, focus: $songFocus)
            customTextField(title: "Favourite Book", text: $book, focus: $bookFocus)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    EditFavouriteMedia()
}

extension EditFavouriteMedia {
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, focus: FocusState<Bool>.Binding) -> some View {
        let isFocused = focus.wrappedValue
        
        VStack(alignment: .leading) {
            Text(title)
                .font(.body(18, .bold))
            
            TextField("Type Here", text: text)
                .padding()
            .focused(focus)
            
            
            .stroke(20, lineWidth: 1, color: isFocused ? .accent : .grayPlaceholder)
        }
    }
}

/*
 
 .padding()
 .background(
     RoundedRectangle(cornerRadius: 20)
         .foregroundStyle(Color.clear)
         .shadow(color: Color.black.opacity(0.1), radius: 10, y: isFocused ? 5 : 0)
 )
 */
