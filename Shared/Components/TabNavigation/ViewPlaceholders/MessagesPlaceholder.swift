//
//  MessagesPlaceholder.swift
//  Scoop Test
//
//  Created by Art Ostin on 11/07/2026.
//

import SwiftUI

struct MessagesPlaceholder: View {
    var body: some View {
        
        
            VStack(spacing: 48) {
                Image("CoolGuys")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(width: 275, height: 275)
                
                
                Text("After meeting, you can message people here")
                    .font(.body(18, .medium))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 48)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.titleGap + 36)
    }
}

#Preview {
    MessagesPlaceholder()
}
