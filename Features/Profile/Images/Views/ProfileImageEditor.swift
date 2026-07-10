//
//  ProfileImageEditor.swift
//  Scoop
//
//  Created by Art Ostin on 16/01/2026.
//

import SwiftUI
import PhotosUI
import SwiftyCrop

struct ProfileImageEditor: View {
    
    //Injected
    @Environment(\.dismiss) var dismiss
    let onSave: (ImageSlot) -> Void

    //Local view state
    @State private var importedImage: ImageSlot
    @State private var item: PhotosPickerItem?
    @State private var showImageCropper: Bool = false
    
    init(importedImage: ImageSlot, onSave: @escaping (ImageSlot) -> Void) {
        self._importedImage = State(initialValue: importedImage)
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: Spacing.xl) {
                Text("Edit Picture")
                    .font(.body(17, .bold))
                
                ScoopImage(image: importedImage.image, aspectRatio: .card)
                    .overlay(alignment: .bottomTrailing) { changeImageButton }
                    .overlay(alignment: .bottomLeading) { cropPhotoIcon }
                
                
                saveButton
                    .padding(.top, Spacing.lg)
            }
            .padding(.top, 120) //Geometry: drops the editor block clear of the status/cancel zone
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            cancelButton
        }
        .task(id: item) { await loadImage() }
        .fullScreenCover(isPresented: $showImageCropper) {cropView}
    }
}

//Buttons
extension ProfileImageEditor {
    
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .foregroundStyle(Color.textTertiary)
                .font(.body(14, .medium))
                .frame(minWidth: 50, minHeight: 50, alignment: .center)   //Fixes bug so Icon is in centre of its tappable area
                .padding(.horizontal, Spacing.md)
                .contentShape(Rectangle())
        }
        .padding(.top, Spacing.md)
        .padding(.trailing, Spacing.xs)
        .zIndex(1)
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
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.white )
                        .shadow(.button)
                )
                .overlay (
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(.black, lineWidth: 1)
                )
        }
    }
    
    private var changeImageButton: some View {
        PhotosPicker(selection: $item, matching: .images) {
            HStack(spacing: Spacing.xs) {
                Image("ChangeIconWhite")
                
                Text("Change Photo")
                    .foregroundStyle(.white)
                    .font(.body(12, .bold))
            }
            .frame(width: 115, height: 28)
            .background(Color.black.opacity(0.5), in: .rect(cornerRadius: CornerRadius.xs))
            .padding()
        }
    }
    
    private var cropPhotoIcon: some View {
        Button {
            showImageCropper = true
        } label: {
            Image("CropImageIcon")
        }
        .frame(width: 30, height: 28)
        .background(Color.black.opacity(0.5), in: .rect(cornerRadius: CornerRadius.sm))
        .padding()
    }
    
    private func loadImage () async {
        guard let item = item else { return }
        //Optional read: a failed pick keeps the current image
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            importedImage.image = uiImage
        }
    }
}

extension ProfileImageEditor {
     
    private var cropView: some View {
        let configuration = SwiftyCropConfiguration(maxMagnificationScale: 6.0, zoomSensitivity: 6.0)
        return SwiftyCropView(
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
