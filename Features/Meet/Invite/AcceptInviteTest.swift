//
//  ContentTransitionTest.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

struct AcceptInviteTest: View {
    
    
    var body: some View {
        ZStack {
            CustomScreenCover {}
                
                RoundedRectangle(cornerRadius: 36)
                    .frame(height: 400)
                    .frame(width: 365)
                    .foregroundStyle(Color.background)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 6)
                        
        }
    }
}
