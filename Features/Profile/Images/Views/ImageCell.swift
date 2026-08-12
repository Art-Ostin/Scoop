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
    let size: CGFloat //The onboarding grid's fixed cell; the profile grid draws its own ProfilePhoto, so its badge can hide in flight

    var body: some View {
        SmallImage(image: image, size: size)
            .overlay(alignment: .topTrailing) {
                ImageEditButton()
                    .padding(Spacing.xxs)
            }
            .contentShape(Rectangle())
    }
}

/// One cell of the profile photo grid: a near-square fill crop, sized by whatever
/// width the grid column offers. It is a zoom-morph SOURCE, so it carries no
/// chrome of its own — the edit badge rides above it as card overlay, where the
/// flight can fade it out instead of flying it.
struct ProfilePhoto: View {
    static let aspectRatio: CGFloat = 1/1.02

    let image: UIImage
    var cornerRadius: CGFloat = CornerRadius.smallImage

    var body: some View {
        Color.clear
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay { Image(uiImage: image).resizable().scaledToFill() }
            .clipShape(.rect(cornerRadius: cornerRadius))
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
            .scaleEffect(0.6, anchor: .trailing)
            .offset(y: -2)
    }
}
