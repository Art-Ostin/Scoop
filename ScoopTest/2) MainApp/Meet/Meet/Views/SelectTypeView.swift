//
//  SelectTypeView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct SelectTypeView: View {
    
    @Binding var typeDefaultOption: String
    
    @Binding var showTypePopup: Bool
        
    
    

    private let options: [(emoji: String, label: String)] = [
        
        ("🍕", "Grab Food"),
        ("🍻", "Grab a drink"),
        ("🎉", "House Party"),
        ("🎑", "Double Date"),
        ("🕺🏻", "Same Place"),
        ("✒️", "Write a message")
        
    ]
    
    var body: some View {
        VStack (spacing: 18){
            
            ForEach(options.indices, id: \.self) { index in
                row(image: options[index].emoji, text: options[index].label)
                    .onTapGesture {
                        typeDefaultOption.removeAll()
                        typeDefaultOption.append(options[index].label)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showTypePopup.toggle()
                        }
                    }

                if index < options.count - 1 {
                    Divider()
                }
                
            }
        }
        .padding( [.top, .bottom, .leading], 24)
        .frame(width: 325)
        .background(Color.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
    }
}

//#Preview {
//    SelectTypeView(selectedTypeOption: $)
//}

extension SelectTypeView {
    
    private func row (image: String, text: String) -> some View {
        
        HStack (spacing: 24) {
            Text(image)
            Text(text)
                .font(.body(18, .medium))
            Spacer()
        }
        
    }
}
