//
//  SelectTimeMessage.swift
//  Scoop
//
//  Created by Art Ostin on 14/04/2026.
//

import SwiftUI

struct SelectTimeMessage: View {
    
    let type: Event.EventType
    let dayCount: Int
    let showTimePopup: Bool
    
    var text: String? {
        if (type == .doubleDate || type == .drink) && dayCount == 1 {
            return "Propose at least 2 days"
        } else if showTimePopup && dayCount >= 2 {
            return "\(dayCount) days proposed; when they accept, they choose only 1"
        } else {
            return nil
        }
    }
    
    var body: some View {
            if let text {
                Text(text)
                    .id(text)
                    .multilineTextAlignment(.center)
                    .font(.title(14, .bold))
                    .lineSpacing(6)
                    .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .transition(.opacity)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 144)
                    .padding(.horizontal, 36)
                    .animation(.easeInOut(duration: 0.2), value: text)
            }
    }
}
