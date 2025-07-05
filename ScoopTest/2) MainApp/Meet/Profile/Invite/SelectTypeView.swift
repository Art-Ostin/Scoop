//
//  SelectTypeView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI


@Observable class SelectTypeViewModel {
    
    
    
    
}



struct SelectTypeView: View {
    
    @Binding var typeDefaultOption: String
    
    @Binding var showTypePopup: Bool
    
    var body: some View {
        VStack (spacing: 18){
            
            ForEach(EventType.allCases, id: \.self) {event in
                let desc = event.description
                row(image: desc.emoji, text: desc.label)
                    .onTapGesture {
                        handleTap(event.description.label)
                    }
                if event != EventType.allCases.last {
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

#Preview {
    SelectTypeView(typeDefaultOption: .constant("true"), showTypePopup: .constant(false))
}

extension SelectTypeView {
    
    private func row (image: String, text: String) -> some View {
        
        HStack (spacing: 24) {
            Text(image)
            Text(text)
                .font(.body(18, .medium))
            Spacer()
        }
    }
    
    private func handleTap (_ title: String) {
        typeDefaultOption.removeAll()
        typeDefaultOption.append(title)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showTypePopup.toggle()
        }
    }
}
