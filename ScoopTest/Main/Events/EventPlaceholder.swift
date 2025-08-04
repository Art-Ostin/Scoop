//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventPlaceholder: View {
    
    let title: String = "eeting"
    
    let imageName: String = "CoolGuys"
    
    var body: some View {
        
            VStack (spacing: 72) {
                
                TitleSection()
                
                Image(imageName)
                    .resizable()
                    .frame(width: 280, height: 280)
                
                Text("Details of your Upcoming Meet Ups appear Here")
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .font(.body(18, .medium))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 72)
            .padding(.horizontal, 32)
    }
}



#Preview {
    EventPlaceholder()
}

struct TitleSection: View {
    
    var isEvent: Bool = false
    
    var body: some View {
        
        HStack(spacing: 3) {
            Image("MIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            Text("eeting")
                .font(.title())
            
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}



