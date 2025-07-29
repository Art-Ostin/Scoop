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
    
    var body: some View {
        
        DropDownMenu {
            ForEach(EventType.allCases, id: \.self) {event in
                customRow(image: event.description.emoji, text: event.description.label)
                    .onTapGesture {
                        handleTap(event.description.label)
                    }
                if event != EventType.allCases.last {
                    SoftDivider()
                }
            }
        }
    }
}

#Preview {
    SelectTypeView(typeDefaultOption: .constant("true"), showTypePopup: .constant(false))
}

extension SelectTypeView {

        private func handleTap (_ title: String) {
        typeDefaultOption.removeAll()
        typeDefaultOption.append(title)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showTypePopup.toggle()
        }
    }
}
