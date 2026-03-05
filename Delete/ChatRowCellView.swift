//
//  ChatRowCellView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI

struct ChatRowCellView: View {
    var body: some View {
        HStack(spacing: 24) {
            Image("")
                .resizable()
                .scaledToFill()
                .frame(width: 65, height: 65)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Arthur")
                    .font(.body(20, .bold))
                
                Text("Hello World")
                    .font(.body(15, .bold))
                    .foregroundStyle(.black)
                    .lineSpacing(6)
                    .lineLimit(1)
            }
        }
        .frame(height: 90, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ChatRowCellView()
}
