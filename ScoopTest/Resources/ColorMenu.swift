//
//  ColorMenu.swift
//  ScoopTest
//
//  Created by Art Ostin on 20/06/2025.
//

import SwiftUI



extension Color {
    
    static let background = Color (red: 0.98, green: 0.98, blue: 0.98)
    
    static let grayBackground = Color (red: 0.93, green: 0.93, blue: 0.93)
    
    static let grayText = Color (red: 0.6, green: 0.6, blue: 0.6)
    
    
}




extension View {
    func offWhite() -> some View {
        ZStack {
            Color.background.ignoresSafeArea()
            self
        }
    }
}

