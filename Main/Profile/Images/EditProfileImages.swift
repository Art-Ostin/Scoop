//
//  ProfileImagesEditing.swift
//  Scoop
//
//  Created by Art Ostin on 16/01/2026.
//

import SwiftUI
import PhotosUI
import SwiftyCrop

struct ProfileImagesEditing: View {

    @State private var importedImage: SelectedImage
    @Environment(\.dismiss) private var dismiss
    @State private var imageSize: CGFloat = 0
    @State private var item: PhotosPickerItem?
    @State private var showImageCropper: Bool = false

    let onSave: (SelectedImage) -> Void

    init(importedImage: SelectedImage, onSave: @escaping (SelectedImage) -> Void) {
        self._importedImage = State(initialValue: importedImage)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 60) {
            cancelButton
            VStack(spacing: 36) {
                Text("Edit Picture")
                    .font(.body(17, .bold))
                
                Image(uiImage: importedImage.image)
                    .resizable()
                    .defaultImage(imageSize, 16)
                    .overlay(alignment: .bottomTrailing) {changeImageButton}
                    .overlay(alignment: .bottomLeading) { cropPhotoIcon}
                
                saveButton
                    .padding(.top, 24)
            }
        }
        .measure(key: ImageSizeKey.self) {$0.frame(in: .global).width}
        .onPreferenceChange(ImageSizeKey.self) { screenWidth in
            imageSize = screenWidth - 16
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 36)
        .task(id: item) { await loadImage()}
        .fullScreenCover(isPresented: $showImageCropper) {
            let configuration = SwiftyCropConfiguration(
                maxMagnificationScale: 6.0, zoomSensitivity: 6.0
            )
                SwiftyCropView(
                    imageToCrop: importedImage.image,
                    maskShape: .square,
                    configuration: configuration
                ) { croppedImage in
                    if let newCroppedImage = croppedImage {
                        importedImage.image = newCroppedImage
                    }
                }
        }
    }
}

extension ProfileImagesEditing {
    
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(Color.grayText)
                .font(.body(14, .medium))
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
    }
    
    private var saveButton: some View {
        Button {
            onSave(importedImage)
            dismiss()
        } label : {
            Text("Save")
                .font(.body(20, .bold))
                .frame(width: 90, height: 37)
                .foregroundStyle(.accent)
                .background (
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white )
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                )
                .overlay (
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.black, lineWidth: 1)
                )
        }
    }
    
    private var changeImageButton: some View {
        PhotosPicker(selection: $item, matching: .images) {
            HStack(spacing: 8) {
                Image("ChangeIconWhite")
                
                Text("Change Photo")
                    .foregroundStyle(.white)
                    .font(.body(12, .bold))
            }
            .frame(width: 115, height: 28)
            .background (
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.black.opacity(0.5))
            )
            .padding()
        }
    }
    
    private var cropPhotoIcon : some View {
        Button {
            showImageCropper = true
        } label: {
            Image("CropImageIcon")
        }
        .frame(width: 30, height: 28)
        .background (
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(Color.black.opacity(0.5))
        )
        .padding()
    }
    
    private func loadImage () async {
        guard let item = item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                importedImage.image = uiImage
                importedImage.imageData = data
            }
        } catch {
            print(error)
        }
    }
    
}


/*
 
 init(importedImage: SelectedImage, images: Binding<[UIImage?]>) {
     _importedImage = State(initialValue: importedImage)
 }
 

 
 HStack(spacing: 8) {
     Image("CropImageIcon")
     
     Text("Crop")
         .foregroundStyle(.white)
         .font(.body(12, .bold))
 }

 */

/*
 @Binding var images: [UIImage?]

 */


