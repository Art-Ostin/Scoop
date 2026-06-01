//
//  CloseViewButton.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI



enum DismissType { case back, cross}

//Creates custom formatted toolbar Item, called then with .toolbar{DismissToolbarItem(.back)}
struct DismissToolbarItem: ToolbarContent {

    @Environment(\.dismiss) private var dismiss

    let dismissType: DismissType
    var isLeading: Bool
    
    //Custom init used so can call it with just .back
    init(_ dismissType: DismissType, isLeading: Bool = true) {
        self.dismissType = dismissType
        self.isLeading = isLeading
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: isLeading ? .topBarLeading : .topBarTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: dismissType == .cross ? "xmark" : "chevron.back")
                    .font(.system(size: 12, weight: .heavy))
            }
        }
    }
}
