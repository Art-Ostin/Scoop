//
//  RespondMessageRow.swift
//  Scoop
//
//  Created by Art Ostin on 28/03/2026.
//

import SwiftUI

struct RespondMessageRow: View {
    
    @Binding var showTypeMessage: Bool
    
    
    let eventMessage: String
    
    
    var body: some View {
        HStack(spacing: 24) {
            Image("SmallMessageIcon")
                .scaleEffect(1.1)
            
            Text(eventMessage)
                .font(.body(14, .regular))
                .lineSpacing(4)
                .foregroundStyle(Color(red: 0.21, green: 0.21, blue: 0.21))
        }
    }
}
