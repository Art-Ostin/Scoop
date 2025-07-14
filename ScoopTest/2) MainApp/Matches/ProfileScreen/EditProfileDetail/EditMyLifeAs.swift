//
//  EmbodyYou.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct EditMyLifeAs: View {
    
    @State var selection: Int = 0
    
    @State var selectedMovie: String = ""
    @State var selectedSong: String = ""
    @State var selectedBook: String = ""
    
    @State var typeSelection: [String] = ["Movie", "Song", "Book"]
    
    @FocusState var isFocused: Bool
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 120)  {
            
            Text("My Life as a" + " \(typeSelection[selection])")
                .font(.title(32, .bold))
                .padding(.top, 96)
                .padding(.horizontal)

            
            TabView(selection: $selection) {
                Group {
                    textField(placeholder: "What movies encapsulates 'you'", selectedOption: $selectedMovie)
                        .tag(0)
                    
                    textField(placeholder: "What song encapsulates 'you' ", selectedOption: $selectedSong)
                        .tag(1)
                    
                    textField(placeholder: "What book encapsulates 'you' ", selectedOption: $selectedBook)
                        .tag(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .tabViewStyle(PageTabViewStyle())
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    EditMyLifeAs()
}

extension EditMyLifeAs {
    
    
    
    private func textField(placeholder: String, selectedOption: Binding<String>) -> some View {
        
        return VStack {
            TextField(placeholder, text: selectedOption)
                .frame(maxWidth: .infinity)
                .font(.body(24))
                .focused($isFocused)
            
            
            RoundedRectangle(cornerRadius: 20, style: .circular)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle (Color(red: 0.48, green: 0.48, blue: 0.48))
            
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
}
