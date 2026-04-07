//
//  RespondWithMessage.swift
//  Scoop
//
//  Created by Art Ostin on 06/04/2026.
//

import SwiftUI

struct RespondWithMessage: View {
    let message: String
    
    var body: some View {
       Text(message)
            .font(.body(14, .medium))
            .lineSpacing(2)
            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.93))
            )
            .overlay(alignment: .topLeading) {
                Text("\"")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .font(.body(16, .medium))
            }
            .overlay(alignment: .bottomTrailing) {
                Text("\"")
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .font(.body(16, .medium))
            }
    }
}

