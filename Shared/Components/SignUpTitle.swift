//
//  SignUpTitle.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct SignUpTitle: View {
    
    let text: String
    var count: Int = 0
    var subtitle: String = ""
    
    let step: String = ""
    
    var body: some View {
        
        HStack(alignment: .bottom, spacing: 12) {
            Text(text)
                .font(.title())
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
            
            Text(subtitle)
                .font(.title(12, .medium))
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
            
            Spacer()
            
            if !step.isEmpty {
                Text("\(step)/12")
                    .font(.body(12, .bold))
            }
        }
    }
}

#Preview {
    SignUpTitle(text: "Hello", count: 3 , subtitle: "(Max 3)")
        .padding(.horizontal)
}
