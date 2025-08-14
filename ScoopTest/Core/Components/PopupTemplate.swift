//
//  InvitePage.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct PopupTemplate<Content: View>: View {
    
    let image : UIImage
    var title: String
    @ViewBuilder let content: () -> Content
    
    
    var body: some View {

        VStack (spacing: 32) {
            
            HStack{
                CirclePhoto(image: image)
                
                Text(title)
                    .font(.title(24))
            }
            content()
        }
        .frame(alignment: .top)
        .padding(.top, 24)
        .padding([.leading, .trailing, .bottom], 32)
        .frame(width: 365)
        .background(Color.background)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
    )
    }
}
