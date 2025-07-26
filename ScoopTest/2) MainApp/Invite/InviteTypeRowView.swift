//
//  InviteRowView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct InviteTypeRowView: View {
    
    var typeDefaultOption: String
    
    @Binding var typeInputText: String

    @Binding var showTypePopup: Bool
    
    @Binding var showMessageScreen: Bool

    
    
    var body: some View {
        
        let showTitle: Bool = typeInputText.isEmpty && typeDefaultOption.isEmpty
        
        let showDefault: Bool = typeInputText.isEmpty  && !typeDefaultOption.isEmpty
        
        let showText: Bool = !typeInputText.isEmpty
        
        var font: Font {
            
            if showTitle {
                return .body(20, .bold)
            } else if showDefault {
                return .body(18)
            } else if showText {
                return .body(14, .medium)
            } else {
                return .body(16, .medium)
            }
        }
        
        HStack {
            
            VStack (spacing: 6) {
                Text(showTitle ? "Type" : (showText ? typeInputText : typeDefaultOption))
                    .font(font)
                
                if !typeDefaultOption.isEmpty && typeInputText.isEmpty {
                    Text("Add a Message")
                        .font(.body(14, .medium))
                        .foregroundStyle(.accent)
                        .onTapGesture {
                            showMessageScreen.toggle()
                        }
                }
            }
            
            Spacer()
            
            Image(showTitle ? "InviteType" : "EditButton")
                .onTapGesture {
                    withAnimation(.spring()){
                        showTypePopup.toggle()
                    }
                }
        }
    }
}

#Preview {
    InviteTypeRowView(typeDefaultOption: "", typeInputText: .constant(""), showTypePopup: .constant(false), showMessageScreen: .constant(false))
}
