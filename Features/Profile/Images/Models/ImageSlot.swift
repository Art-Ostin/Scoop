//
//  ImageSlot.swift
//  Scoop
//
//  Created by Art Ostin on 18/01/2026.
//

import SwiftUI


struct ImageSlot: Identifiable, Equatable {
    let index: Int
    var image: UIImage
    var id: Int { index }
}

