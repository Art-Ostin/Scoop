//
//  EditPhotoCell2.swift
//  Scoop
//
//  Created by Art Ostin on 31/10/2025.
//

import SwiftUI
import PhotosUI

struct OnboardingPhotoCell: View {

    @Binding var selectedImage: SelectedImage?
    @State var pickerItem: PhotosPickerItem?
    let index: Int
    @Binding var image: UIImage?
    
    var body: some View {
        Group {
            if let image {
                ImageCell(image: image, size: 120)
                    .onTapGesture {selectedImage = SelectedImage(index: index, image: image)}
            } else {
                placeHolderView
            }
        }
        .shadow(color: selectedImage?.index == index ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 5)
        .task(id: pickerItem) {await loadPickedImage()}
    }
}

extension OnboardingPhotoCell {
    private var placeHolderView: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Image("ImagePlaceholder")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    func loadPickedImage () async {
        guard let item = selectedImage?.pickerItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage?.image = uiImage
                self.image = uiImage
            }
        } catch {
            print(error)
        }
    }
}

struct ImageCell: View {
    let image: UIImage
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .defaultShadow()
            RoundedRectangle(cornerRadius: 10)
                .frame(width: size, height: size)
                .foregroundStyle(Color.clear)
                .overlay(alignment: .topTrailing) {
                    ImageEditButton()
                        .padding(4)
                }
        }
        .contentShape(Rectangle())
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
       Image(editButton)
           .resizable()
           .scaledToFit()
           .frame(width: 11, height: 11)
           .padding(3)
           .glassIfAvailable(Circle())
   }
}



/* Do not Delete
 @MainActor in
 guard let item = selectedImage?.pickerItem else { return }
 do {
     if let data = try await item.loadTransferable(type: Data.self),
        let uiImage = UIImage(data: data) {
         selectedImage?.image = uiImage
         self.image = uiImage
     }
 } catch {
     print(error)
 }

 */
