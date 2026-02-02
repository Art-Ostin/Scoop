//
//  ExpandTapArea.swift
//  Scoop
//
//  Created by Art Ostin on 20/01/2026.
//

import SwiftUI

//Expands the tap area of the view, by adding 16 padding around it, but without affecting the layout
extension View {
    func customExpandTapArea(inset: CGFloat = 16) -> some View {
        self
            .padding(inset)
            .contentShape(Rectangle())
            .padding(-inset)
    }
}
