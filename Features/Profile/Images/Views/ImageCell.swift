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
    let size: CGFloat
    var body: some View {
        ZStack {
            
            SmallImage(image: image, size: size)
                .shadow(.floating)
            
            RoundedRectangle(cornerRadius: CornerRadius.smallImage)
                .frame(width: size, height: size)
                .foregroundStyle(Color.clear)
                .overlay(alignment: .topTrailing) {
                    ImageEditButton()
                        .padding(Spacing.xxs)
                }
        }
        .contentShape(Rectangle())
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
   
   private var editButton: String {
       if #available(iOS 26.0, *) {
           return "EditWhiteButton" //If Using liquid glass
       } else {
           return "EditButtonBlack"  // If not just black
       }
   }
   var body: some View {
       EmptyView() // TODO: restore the glass edit badge (removed during ButtonTest preview work)
   }
}
