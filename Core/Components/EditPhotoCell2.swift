//
//  EditPhotoCell2.swift
//  Scoop
//
//  Created by Art Ostin on 31/10/2025.
//

import SwiftUI
import PhotosUI



struct EditPhotoCell2: View {

    @Binding var image: UIImage?
    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(alignment: .topTrailing) {
                        ImageEditButton()
                    }
            } else {
                Image("ImagePlaceholder")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: image != nil ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
        .task(id: item) { @MainActor in
            guard let item = item else { return }
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            } catch {
                print(error)
            }
        }
    }
}


struct ImageEditButton: View {
    var body: some View {
        Image("EditButtonBlack")
            .resizable()
            .scaledToFit()
            .frame(width: 13, height: 13)
            .padding(3)
            .background (
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
    }
}

