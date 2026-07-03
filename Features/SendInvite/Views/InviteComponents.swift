//
//  InviteComponents.swift
//  Scoop
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
            .foregroundStyle(Color.textTertiary)
            .opacity(dimmed ? 0.3 : 1)
    }
}

