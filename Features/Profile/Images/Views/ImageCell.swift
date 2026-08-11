//
//  EditPhotoCell2.swift
//  Scoop
//
//  Created by Art Ostin on 31/10/2025.
//

import SwiftUI
import PhotosUI

struct ImageCell: View {
    let image: UIImage
    var size: CGFloat? = nil //nil squares off to whatever width the container offers (the photo grid)

    var body: some View {
        photo
            .shadow(.tile)
            .overlay(alignment: .topTrailing) {
                ImageEditButton()
                    .padding(Spacing.xxs)
            }
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private var photo: some View {
        if let size {
            SmallImage(image: image, size: size)
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { Image(uiImage: image).resizable().scaledToFill() }
                .clipShape(.rect(cornerRadius: CornerRadius.smallImage))
        }
    }
}

struct OnboardingPhotoCell: View {

    //Injected
    @Binding var selectedImage: ImageSlot?
    let index: Int
    @Binding var image: UIImage?

    //Local view state
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        Group {
            if let image {
                ImageCell(image: image, size: 120)
                    .onTapGesture {selectedImage = ImageSlot(index: index, image: image)}
            } else {
                placeHolderView
            }
        }
        .shadow(.button, strength: selectedImage?.index == index ? 1 : 0)
        .task(id: pickerItem) {await loadPickedImage()}
    }
}

extension OnboardingPhotoCell {
    private var placeHolderView: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            imagePlaceholder
        }
    }
        
    private var imagePlaceholder: some View {
        Image("ImagePlaceholder")
            .resizable()
            .scaledToFill()
            .frame(width: 120, height: 120)
            .clipShape(.rect(cornerRadius: CornerRadius.smallImage))
    }
    
    func loadPickedImage () async {
        guard let item = pickerItem else { return }
        //Optional read: a failed pick just leaves the placeholder
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            self.image = uiImage
        }
    }
}

struct ImageEditButton: View {

    var body: some View {
        Image("PhotoChangeBadge3D")
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 28, height: 28)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .scaleEffect(0.7, anchor: .trailing)
            .offset(y: -1)
    }
}
