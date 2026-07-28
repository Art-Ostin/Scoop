//
//  ConfirmInfoScreen.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct ConfirmInfoScreen: View {
    
    let type: Event.EventType
    
    var body: some View {
        Text(type.longTitle)
    }
}
