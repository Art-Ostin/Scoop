//
//  PhotoCell2.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
//

import SwiftUI
import PhotosUI


struct PhotoCell2: View {
    
    @Binding var picker: PhotosPickerItem?
    let urlString: String?
    var image:  UIImage?
    let action: () -> Void
    
    var body: some View {
        
        PhotosPicker(selection: $picker, matching: .images) {
            
            if let image = self.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let url = urlString, let url = URL(string: url) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(alignment: .topTrailing) {
                            ChangeIcon()
                                .padding()
                        }
                } placeholder: {ProgressView()}
                
            } else {
                Image("ImagePlaceholder2")
                    .resizable()
                    .scaledToFill()
            }
        }
        .id(urlString)
        .frame(width: 110, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: urlString != nil ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
        .onChange(of: picker) { action() }
    }
}

#Preview {
    PhotoCell2(picker: .constant(PhotosPickerItem(itemIdentifier: "Yes")), urlString: "Helo World", action: {})
}

struct ChangeIcon: View {
    var body: some View {
        Image("ChangeIcon")
            .padding(12)
            .frame(width: 24, height: 24)
            .background (
                Circle()
                    .fill(Color.white)
            )
            .padding(6)
    }
}

