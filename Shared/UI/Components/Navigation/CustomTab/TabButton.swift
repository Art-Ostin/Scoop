//
//  InfoTest.swift
//  Scoop
//
//  Created by Art Ostin on 27/10/2025.
//

import SwiftUI

struct TabButton: View {
    let page: Page
    @Binding var isPresented: Bool
    
    var body: some View {
        
        switch page {
        case .meet, .meetingNoEvent, .invites:
            TabInfoButton(showScreen: $isPresented)
            
        case .meetingEvent:
            messageButton
            
        default:
            EmptyView()
        }
    }
}

extension TabButton {
    
    private var messageButton: some View {
        Button {
            isPresented = true
        } label: {
            Image("roundMessageIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .font(.body(17, .bold))
                .padding(6)
                .glassIfAvailable(isClear: true)
                .padding(24) //Expands Tap Area
                .contentShape(Rectangle())
                .padding(-24)
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
        }
    }
}



