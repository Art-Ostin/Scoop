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
                .scaleEffect(1.2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Message")
                    .font(.body(16, .medium))
                Text(eventMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.grayText)
                    .lineLimit(4)
            }
        }
    }
}
