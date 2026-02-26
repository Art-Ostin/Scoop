//
//  ChatRowView.swift
//  Scoop
//
//  Created by Art Ostin on 26/02/2026.
//

import SwiftUI

struct ChatRowView: View {

    let dummyData: DummyMessage

    
    var body: some View {
        
        HStack(spacing: 24) {
            Image(dummyData.image)
                .resizable()
                .scaledToFill()
                .frame(width: 65, height: 65)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(dummyData.person)
                    .font(.body(20, .bold))
                
                Text(dummyData.text)
                    .font(.body(15, dummyData.isBold ? .bold : .regular))
                    .foregroundStyle(dummyData.isBold ? .black : .grayText)
                    .lineSpacing(6)
                    .lineLimit(1)
            }
        }
        .frame(height: 90, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
