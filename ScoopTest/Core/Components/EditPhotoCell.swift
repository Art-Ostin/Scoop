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
    let image: UIImage?
    let action: () async throws -> Void
    
    var body: some View {
        
        PhotosPicker(selection: $picker, matching: .images) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("ImagePlaceholder2")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 110, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: image != nil ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
        .onChange(of: picker) {_, newValue in
            guard newValue != nil else { return }
            Task {
                do { try await action() }
                catch { print("changeImage failed:", error) }
            }
        }
    }
}
