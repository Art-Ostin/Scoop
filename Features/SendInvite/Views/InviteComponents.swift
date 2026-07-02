//
//  InviteComponents.swift
//  Scoop Test
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI


struct RowCaption: View {
    enum Label: String { case what, when, `where` }
    
    let label: Label
    let dimmed: Bool
    
    var body: some View {
        Text(label.rawValue.uppercased())
            .font(.body(11, .regular))
            .foregroundStyle(Color(red: 0.70, green: 0.70, blue: 0.75))
            .opacity(dimmed ? 0.3 : 1)
    }
}

