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
    @Environment(\.zoomDismiss) private var zoomDismiss //Collapses the screen back into its photo cell
    let onSave: (ImageSlot) -> Void

    //Local view state
    @State private var importedImage: ImageSlot
    @State private var item: PhotosPickerItem?
    @State private var showImageCropper: Bool = false
    @State private var chipsIn: Bool = false //The image's own chips arrive over the zoom, not after it

    init(importedImage: ImageSlot, onSave: @escaping (ImageSlot) -> Void) {
        self._importedImage = State(initialValue: importedImage)
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: Spacing.xl) {
                Text("Edit Picture")
                    .font(.body(17, .bold))

                heroPhoto

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

    //The image that flew in. These pixels belong to the transition's UIKit hero, so the
    //editor's working copy is handed DOWN to it — drawing our own would double the photo.
    //The chips carry the hero's own side inset so they hug the image, not the slot.
    private var heroPhoto: some View {
        ImageCarousel(horizontalPadding: Spacing.md, aspectRatio: Self.heroAspect,
                      displaying: importedImage.image)
            //The chips ride the flight in, so they arrive on the growing image
            //rather than landing on a screen that has already settled. The fade
            //sits on the chips alone — the hero's pixels belong to the
            //transition and must never fade with them.
            .overlay(alignment: .bottomTrailing) {
                changeImageButton
                    .padding(.horizontal, Spacing.md)
                    .opacity(chipsIn ? 1 : 0)
            }
            .overlay(alignment: .bottomLeading) {
                cropPhotoIcon
                    .padding(.horizontal, Spacing.md)
                    .opacity(chipsIn ? 1 : 0)
            }
            .animation(.transition, value: chipsIn)
            .onAppear { chipsIn = true }
    }

    //Height = width × this: the crop AppImage(.meet) drew here before the hero took the slot
    private static let heroAspect: CGFloat = 1.2

    private var cancelButton: some View {
        Button {
            zoomDismiss()
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
            zoomDismiss()
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
