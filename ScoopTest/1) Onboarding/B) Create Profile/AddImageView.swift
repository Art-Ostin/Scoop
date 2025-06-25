//
//  AddImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 21/06/2025.
//

import SwiftUI

struct AddImageView: View {
    
    var body: some View {
        
        VStack (spacing: 24) {
            
            VStack (spacing: 48)  {
                SignUpTitle(text: "Add 6 Photos")
                
                HStack{
                    Spacer()
                    Text("Ensure you're in all")
                        .font(.body(.bold))
                        .foregroundStyle(Color(red: 0.53, green: 0.53, blue: 0.53))
                    Spacer()
                }
            }
            VStack(spacing: 24) {
                VStack(spacing: 12){
                    Text("main")
                        .font(.body(12, .bold))
                        .offset(x: -126)
                    HStack(spacing: 34){
                        Image("ImagePlaceholder")
                        Image("ImagePlaceholder")
                        Image("ImagePlaceholder")
                    }
                }
                HStack(spacing: 34) {
                    Image("ImagePlaceholder")
                    Image("ImagePlaceholder")
                    Image("ImagePlaceholder")
                }
                HStack {
                    Text("Drag to reorder")
                        .font(.body(12, .regular))
                        .foregroundStyle(Color(red: 0.63, green: 0.63, blue: 0.63))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    NextButton(isEnabled: true, onInvalidTap: {}, isSubmit: true)
                }
            }
        }
    }
}

#Preview {
    AddImageView()
        .environment(AppState())
        .padding(32)
}



