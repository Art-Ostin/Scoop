//
//  ImageModels.swift
//  Scoop
//
//  Created by Art Ostin on 18/01/2026.
//

import SwiftUI
import PhotosUI


struct ImageSlot: Identifiable, Equatable {
    let index: Int
    var image: UIImage
    var jpegData: Data? { image.jpegData(compressionQuality: 1.0) }
    var id: Int { index }
}

