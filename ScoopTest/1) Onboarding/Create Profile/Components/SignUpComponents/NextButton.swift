//
//  NextButton2.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI

struct NextButton: View {
    
    let isEnabled: Bool
    let onTap: () -> Void
    
    
    var body: some View {
        Image("ForwardArrow")
            .frame(width: 69, height: 44, alignment: .center)
            .background(isEnabled ? Color.accent : Color.grayBackground)
            .cornerRadius(33)
            .shadow(color: isEnabled ? .black.opacity(0.25) : .clear , radius: 2, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
            .onTapGesture {
                withAnimation{onTap()}
            }
    }
}

#Preview {
    NextButton(isEnabled: true, onTap: {})
}


