//
//  DropDownButton.swift
//  Scoop
//
//  Created by Art Ostin on 27/01/2026.
//

import SwiftUI

struct DropDownButton: View {
    let isOpen: Bool
    var isAccept: Bool = false
    
    var body: some View {
        Image(isAccept ? "DropDownIconGreen" : "DropdownGray")
            .rotationEffect(.degrees(isOpen ? 90 : 0))
            .animation(.toggle, value: isOpen)
    }
}
