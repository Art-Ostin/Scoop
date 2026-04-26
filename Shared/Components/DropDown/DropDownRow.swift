//
//  DropDownRow.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct DropDownRow: View {
    
    var image: String?
    
    let text: String
    
    let isSelected: Bool
    let isLastRow: Bool
    
    let onTap: () -> ()    
    var body: some View {
        VStack(spacing: 18) {
            HStack (spacing: 24) {
                if let emoji = image {
                   Text(emoji)
                }
                Text(text)
                Spacer()
            }
            if !isLastRow {
                CustomDivider()
                    .padding(.trailing, -24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(isSelected ? Color.appGreen : Color.black)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
