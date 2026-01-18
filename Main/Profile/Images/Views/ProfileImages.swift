//
//  ImageView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/07/2025.
// Allow Editing on their profile and the option to cancel it. To


import SwiftUI
import PhotosUI

//Old
struct ImageSlot: Equatable {
    var pickerItem: PhotosPickerItem?
    var path: String?
    var url: URL?
}

struct ImagesView: View {

    @Bindable var vm: EditProfileViewModel
    @Binding var selectedImage: SelectedImage?
    private let columns = Array(repeating: GridItem(.fixed(105), spacing: 22), count: 3)
    
    var body: some View {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<6) {index in
                    let image = vm.images[index]
                    ImageCell(image: image, size: 110)
                        .onTapGesture {selectedImage = SelectedImage(index: index, image: image)}
                }
            }
    }
}




/*
 EditPhotoCell(picker: $vm.slots[idx].pickerItem, image: vm.images[idx]) {
     try await vm.changeImage(at: idx)
 }
 */

/*
 EditPhotoCell(picker: $vm.slots[idx].pickerItem, image: vm.images[idx]) {
     try await vm.changeImage(at: idx)
 }

 */
