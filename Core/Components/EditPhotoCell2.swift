//
//  EditPhotoCell2.swift
//  Scoop
//
//  Created by Art Ostin on 31/10/2025.
//

import SwiftUI
import PhotosUI



struct EditPhotoCell2: View {

    @State private var item: PhotosPickerItem?
    @Binding var selectedImage: SelectedImage?
    let index: Int
    
    var body: some View {
        Group {
            if let image = selectedImage?.image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                    
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 120, height: 120)
                        .foregroundStyle(Color.clear)
                        .overlay(alignment: .topTrailing) {
                            ImageEditButton()
                                .padding(4)
                        }
                }
                .contentShape(Rectangle())
                .onTapGesture {selectedImage = SelectedImage(index: index, image: image)}
                } else {
                    PhotosPicker(selection: $item, matching: .images) {
                        Image("ImagePlaceholder")
                            .resizable()
                            .scaledToFill()
                    }
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: image != nil ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
        .task(id: item) {
            @MainActor in
            guard let item = item else { return }
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage?.image = uiImage
                }
            } catch {
                print(error)
            }
        }
    }
}


struct ImageEditButton: View {
    private var editButton: String {
        if #available(iOS 26.0, *) {
            return "EditWhiteButton" //If Using liquid glass
        } else {
            return "EditButtonBlack"         // If not just black
        }
    }
    var body: some View {
        Image(editButton)
            .resizable()
            .scaledToFit()
            .frame(width: 11, height: 11)
            .padding(3)
            .glassIfAvailable(Circle())
    }
}

/*
 @Binding var image: UIImage?
 */
