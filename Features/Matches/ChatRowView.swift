//
//  ChatRowView.swift
//  Scoop
//
//  Created by Art Ostin on 26/02/2026.
//

import SwiftUI

struct ChatRowView: View {
    
    let image: UIImage
    
    
    let person: String
    
    
    let text: String
    
    let isBold: Bool

    
    var body: some View {
        
        HStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 12) {
                Text(person)
                    .font(.body(17, .bold))
                
                Text(text)
                    .font(.body(16, isBold ? .bold : .medium))
                    .foregroundStyle(isBold ? .black : .grayText)
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
