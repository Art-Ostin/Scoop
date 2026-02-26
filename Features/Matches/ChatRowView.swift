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
        
        HStack(spacing: 24) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 65, height: 65)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(person)
                    .font(.body(20, .bold))
                
                Text(text)
                    .font(.body(15, isBold ? .bold : .regular))
                    .foregroundStyle(isBold ? .black : .grayText)
            }
        }
        .frame(height: 90, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
