//
//  CloseViewButton.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI


struct DismissToolbarItem: ToolbarContent {
    
    @Environment(\.dismiss) private var dismiss
    let imageString: String
    let isLeading: Bool
    
    init(imageString: String = "xmark", isLeading: Bool = true) {
        self.imageString = imageString
        self.isLeading = isLeading
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: isLeading ? .topBarLeading : .topBarTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: imageString).font(.body.weight(.semibold))
            }
        }
    }
}
