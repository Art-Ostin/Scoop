//
//  TestScreen.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct TestScreen: View {
    
    var body: some View {
        
        VStack(spacing: 6)  {
            Text("Susan Never Showed")
                .font(.body(12, .bold))
                .foregroundStyle(.accent)
                .frame(maxWidth: .infinity, alignment: .center)

            
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 8) {
                    Image("ProfileMockA")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                    
                    Text("Meeting with Arthur")
                        .font(.body(18, .bold))
                    
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Thursday, August 23rd · 22:30 ")
                    Text("Brandy Melville")
                }
            }
            .font(.body(16, .medium))
            .padding(16)
            .frame(width: 320, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color.background)
                    .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
            )
            .stroke(16, lineWidth: 1, color: Color.grayPlaceholder)
            .overlay(alignment: .bottomTrailing) {
                Text("🍻 Drink")
                    .font(.body(14, .bold))
                    .padding()
            }
        }
        
        
        

        
        
//        .overlay(alignment: .topTrailing) {
//            Text("No show")
//                .font(.body(12, .bold))
//                .foregroundStyle(.accent)
//                .padding(.horizontal, 14)
//                .offset(y: 10)
//        }
    }
}

#Preview {
    TestScreen()
}
