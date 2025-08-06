//
//  PhotoCell2.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI
import PhotosUI

struct EditPhotoCell: View {
    
    @Binding var picker: PhotosPickerItem?
    let urlString: String?
    let action: () -> Void
    
    var body: some View {
        
        PhotosPicker(selection: $picker, matching: .images) {
            
            displayedImage
                .resizable()
                .scaledToFill()
            
        }
        .id(urlString)
        .frame(width: 110, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: urlString != nil ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
        .onChange(of: picker) { action() }
    }
    
    @ViewBuilder private var displayedImage: some View {
        if let url = URL(string: urlString ?? "") {
            CachedAsyncImage(url: url) { image in
                image
            }
        } else {
            Image("ImagePlaceholder2")
        }
    }
}
