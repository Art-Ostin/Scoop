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
    
    
    
    var body: some View {
        
        HStack(alignment: .bottom, spacing: 12) {
            
            Text(text)
                .font(.title())
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
            
            Text(subtitle)
                .font(.title(12, .medium))
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
            
            Spacer()
            
            HStack(spacing: 14){
                if count > 0 {
                    ForEach(0..<count, id: \.self) {_ in
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundStyle(.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .inset(by: 0.5)
                                    .stroke(.black, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpTitle(text: "Hello", count: 3 , subtitle: "(Max 3)")
        .padding(.horizontal)
}
